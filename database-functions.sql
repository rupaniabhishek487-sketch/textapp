-- Atomic Points Awarding Function
CREATE OR REPLACE FUNCTION award_points_transaction(
  p_user_id UUID,
  p_points INTEGER,
  p_inr_value NUMERIC,
  p_kind TEXT,
  p_metadata JSONB DEFAULT '{}'
)
RETURNS TABLE(success BOOLEAN, message TEXT) AS $$
DECLARE
  v_transaction_id UUID;
  v_current_points BIGINT;
  v_current_balance NUMERIC;
BEGIN
  -- Start transaction block
  -- Lock the user profile to prevent concurrent modifications
  SELECT total_points, balance_inr INTO v_current_points, v_current_balance
  FROM profiles
  WHERE id = p_user_id
  FOR UPDATE;

  -- Check if user exists
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'User not found'::TEXT;
    RETURN;
  END IF;

  -- Create transaction record
  INSERT INTO transactions (user_id, kind, points, inr_value, meta)
  VALUES (p_user_id, p_kind, p_points, p_inr_value, p_metadata)
  RETURNING id INTO v_transaction_id;

  -- Update user profile atomically
  UPDATE profiles 
  SET 
    total_points = total_points + p_points,
    balance_inr = balance_inr + p_inr_value,
    total_earnings_inr = CASE 
      WHEN p_kind IN ('task_reward', 'referral_bonus', 'bonus') 
      THEN total_earnings_inr + p_inr_value 
      ELSE total_earnings_inr 
    END,
    updated_at = NOW()
  WHERE id = p_user_id;

  -- Return success
  RETURN QUERY SELECT TRUE, 'Points awarded successfully'::TEXT;
  
EXCEPTION
  WHEN OTHERS THEN
    -- Rollback automatically happens on exception
    RETURN QUERY SELECT FALSE, SQLERRM::TEXT;
END;
$$ LANGUAGE plpgsql;

-- Function to get user statistics
CREATE OR REPLACE FUNCTION get_user_stats(p_user_id UUID)
RETURNS TABLE(
  total_points BIGINT,
  balance_inr NUMERIC,
  total_tasks_completed INTEGER,
  total_earnings_inr NUMERIC,
  pending_submissions INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.total_points,
    p.balance_inr,
    p.total_tasks_completed,
    p.total_earnings_inr,
    COALESCE(ps.pending_count, 0)
  FROM profiles p
  LEFT JOIN (
    SELECT user_id, COUNT(*) as pending_count
    FROM task_submissions
    WHERE status = 'pending'
    GROUP BY user_id
  ) ps ON p.id = ps.user_id
  WHERE p.id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- Function to get task statistics
CREATE OR REPLACE FUNCTION get_task_stats()
RETURNS TABLE(
  total_tasks INTEGER,
  active_tasks INTEGER,
  total_submissions INTEGER,
  pending_submissions INTEGER,
  approved_submissions INTEGER,
  rejected_submissions INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    (SELECT COUNT(*) FROM tasks) as total_tasks,
    (SELECT COUNT(*) FROM tasks WHERE active = true) as active_tasks,
    (SELECT COUNT(*) FROM task_submissions) as total_submissions,
    (SELECT COUNT(*) FROM task_submissions WHERE status = 'pending') as pending_submissions,
    (SELECT COUNT(*) FROM task_submissions WHERE status = 'approved') as approved_submissions,
    (SELECT COUNT(*) FROM task_submissions WHERE status = 'rejected') as rejected_submissions;
END;
$$ LANGUAGE plpgsql;

-- Add is_admin field to profiles if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'is_admin'
  ) THEN
    ALTER TABLE profiles ADD COLUMN is_admin BOOLEAN DEFAULT FALSE;
  END IF;
END $$;

-- Add estimated_time and difficulty fields to tasks if they don't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'tasks' AND column_name = 'estimated_time'
  ) THEN
    ALTER TABLE tasks ADD COLUMN estimated_time INTEGER DEFAULT 5;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'tasks' AND column_name = 'difficulty'
  ) THEN
    ALTER TABLE tasks ADD COLUMN difficulty TEXT DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard'));
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'tasks' AND column_name = 'expected_text'
  ) THEN
    ALTER TABLE tasks ADD COLUMN expected_text TEXT;
  END IF;
END $$;

-- Add missing fields to task_submissions if they don't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'task_submissions' AND column_name = 'claimed_at'
  ) THEN
    ALTER TABLE task_submissions ADD COLUMN claimed_at TIMESTAMPTZ;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'task_submissions' AND column_name = 'expires_at'
  ) THEN
    ALTER TABLE task_submissions ADD COLUMN expires_at TIMESTAMPTZ;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'task_submissions' AND column_name = 'reviewed_at'
  ) THEN
    ALTER TABLE task_submissions ADD COLUMN reviewed_at TIMESTAMPTZ;
  END IF;
END $$;