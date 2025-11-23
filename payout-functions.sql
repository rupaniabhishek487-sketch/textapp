-- Deduct Points Transaction Function
CREATE OR REPLACE FUNCTION deduct_points_transaction(
  p_user_id UUID,
  p_points INTEGER,
  p_inr_value NUMERIC
)
RETURNS TABLE(success BOOLEAN, message TEXT) AS $$
DECLARE
  v_current_points BIGINT;
  v_current_balance NUMERIC;
BEGIN
  -- Lock user profile to prevent concurrent modifications
  SELECT total_points, balance_inr INTO v_current_points, v_current_balance
  FROM profiles
  WHERE id = p_user_id
  FOR UPDATE;

  -- Check if user exists
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'User not found'::TEXT;
    RETURN;
  END IF;

  -- Check if user has sufficient points
  IF v_current_points < p_points THEN
    RETURN QUERY SELECT FALSE, 'Insufficient points'::TEXT;
    RETURN;
  END IF;

  -- Check if user has sufficient balance
  IF v_current_balance < p_inr_value THEN
    RETURN QUERY SELECT FALSE, 'Insufficient balance'::TEXT;
    RETURN;
  END IF;

  -- Create transaction record
  INSERT INTO transactions (user_id, kind, points, inr_value, meta)
  VALUES (p_user_id, 'payout', -p_points, -p_inr_value, jsonb_build_object(
    'deducted_at', NOW(),
    'auto_deduct', true
  ));

  -- Update user profile
  UPDATE profiles 
  SET 
    total_points = total_points - p_points,
    balance_inr = balance_inr - p_inr_value,
    updated_at = NOW()
  WHERE id = p_user_id;

  RETURN QUERY SELECT TRUE, 'Points deducted successfully'::TEXT;
  
EXCEPTION
  WHEN OTHERS THEN
    -- Rollback automatically happens on exception
    RETURN QUERY SELECT FALSE, SQLERRM::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add missing fields to payout_requests table if they don't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'payout_requests' AND column_name = 'admin_notes'
  ) THEN
    ALTER TABLE payout_requests ADD COLUMN admin_notes TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'payout_requests' AND column_name = 'paid_at'
  ) THEN
    ALTER TABLE payout_requests ADD COLUMN paid_at TIMESTAMPTZ;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'payout_requests' AND column_name = 'razorpay_payout_id'
  ) THEN
    ALTER TABLE payout_requests ADD COLUMN razorpay_payout_id TEXT;
  END IF;
END $$;