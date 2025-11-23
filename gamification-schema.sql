-- Gamification System Schema and Functions for Earnify

-- Add gamification columns to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS streak_count INTEGER DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_login_date DATE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS current_level INTEGER DEFAULT 1;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS total_earned_points INTEGER DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS daily_bonus_claimed DATE;

-- User badges table
CREATE TABLE IF NOT EXISTS user_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  badge_type VARCHAR(50) NOT NULL, -- 'newbie', 'regular', 'achiever', 'master', 'legend'
  badge_name VARCHAR(100) NOT NULL,
  badge_description TEXT,
  badge_icon VARCHAR(50), -- icon name for UI
  earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE,
  UNIQUE(user_id, badge_type)
);

-- Gamification configuration table
CREATE TABLE IF NOT EXISTS gamification_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  config_key VARCHAR(100) NOT NULL UNIQUE,
  config_value TEXT NOT NULL,
  description TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Daily login history for streak tracking
CREATE TABLE IF NOT EXISTS daily_login_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  login_date DATE NOT NULL,
  bonus_points INTEGER DEFAULT 0,
  streak_updated BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, login_date)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_badges_user_id ON user_badges(user_id);
CREATE INDEX IF NOT EXISTS idx_user_badges_badge_type ON user_badges(badge_type);
CREATE INDEX IF NOT EXISTS idx_daily_login_history_user_id ON daily_login_history(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_login_history_login_date ON daily_login_history(login_date);
CREATE INDEX IF NOT EXISTS idx_profiles_current_level ON profiles(current_level);
CREATE INDEX IF NOT EXISTS idx_profiles_streak_count ON profiles(streak_count);

-- Insert default gamification configuration
INSERT INTO gamification_config (config_key, config_value, description) VALUES
  ('daily_login_bonus', '10', 'Points awarded for daily login'),
  ('streak_bonus_multiplier', '2', 'Multiplier for streak bonus'),
  ('level_threshold', '20', 'Tasks needed per level'),
  ('newbie_threshold', '1', 'Level for Newbie badge'),
  ('regular_threshold', '5', 'Level for Regular badge'),
  ('achiever_threshold', '10', 'Level for Achiever badge'),
  ('master_threshold', '20', 'Level for Master badge'),
  ('legend_threshold', '50', 'Level for Legend badge')
ON CONFLICT (config_key) DO NOTHING;

-- Function to update daily login streak and award bonus
CREATE OR REPLACE FUNCTION update_daily_streak_and_bonus(
  p_user_id UUID,
  p_current_date DATE DEFAULT CURRENT_DATE
) RETURNS INTEGER AS $$
DECLARE
  v_last_login DATE;
  v_streak_count INTEGER;
  v_bonus_points INTEGER := 0;
  v_daily_bonus_points INTEGER;
  v_streak_bonus_points INTEGER := 0;
  v_already_claimed BOOLEAN := FALSE;
  v_new_level INTEGER;
  v_badge_type VARCHAR(50);
  v_badge_name VARCHAR(100);
  v_badge_description TEXT;
  v_badge_icon VARCHAR(50);
BEGIN
  -- Get current streak and last login
  SELECT streak_count, last_login_date, daily_bonus_claimed, current_level
  INTO v_streak_count, v_last_login, v_already_claimed, v_new_level
  FROM profiles 
  WHERE id = p_user_id;
  
  -- Get daily bonus configuration
  SELECT CAST(config_value AS INTEGER) INTO v_daily_bonus_points
  FROM gamification_config 
  WHERE config_key = 'daily_login_bonus';
  
  -- Check if user already claimed bonus today
  IF v_already_claimed = p_current_date THEN
    RETURN 0; -- No bonus, already claimed today
  END IF;
  
  -- Calculate streak
  IF v_last_login IS NULL THEN
    -- First login ever
    v_streak_count := 1;
    v_bonus_points := v_daily_bonus_points;
  ELSIF v_last_login = p_current_date - INTERVAL '1 day' THEN
    -- Consecutive day
    v_streak_count := v_streak_count + 1;
    v_bonus_points := v_daily_bonus_points;
    
    -- Add streak bonus for every 7 days
    IF v_streak_count % 7 = 0 THEN
      SELECT CAST(config_value AS INTEGER) INTO v_streak_bonus_points
      FROM gamification_config 
      WHERE config_key = 'streak_bonus_multiplier';
      
      v_bonus_points := v_bonus_points + (v_daily_bonus_points * v_streak_bonus_points);
    END IF;
  ELSIF v_last_login < p_current_date - INTERVAL '1 day' THEN
    -- Streak broken
    v_streak_count := 1;
    v_bonus_points := v_daily_bonus_points;
  ELSE
    -- Already logged in today
    RETURN 0;
  END IF;
  
  -- Update user profile
  UPDATE profiles 
  SET 
    streak_count = v_streak_count,
    last_login_date = p_current_date,
    daily_bonus_claimed = p_current_date,
    total_earned_points = total_earned_points + v_bonus_points,
    total_points = total_points + v_bonus_points,
    balance_inr = balance_inr + (v_bonus_points * 0.01)
  WHERE id = p_user_id;
  
  -- Record login history
  INSERT INTO daily_login_history (user_id, login_date, bonus_points, streak_updated)
  VALUES (p_user_id, p_current_date, v_bonus_points, TRUE);
  
  -- Create transaction for daily bonus
  INSERT INTO transactions (user_id, kind, points, inr_value, meta, status)
  VALUES (
    p_user_id,
    'bonus',
    v_bonus_points,
    v_bonus_points * 0.01,
    jsonb_build_object(
      'type', 'daily_login_bonus',
      'streak_count', v_streak_count,
      'login_date', p_current_date
    ),
    'completed'
  );
  
  RETURN v_bonus_points;
END;
$$ LANGUAGE plpgsql;

-- Function to update user level and award badges
CREATE OR REPLACE FUNCTION update_user_level_and_badges(
  p_user_id UUID
) RETURNS VOID AS $$
DECLARE
  v_total_tasks INTEGER;
  v_new_level INTEGER;
  v_current_level INTEGER;
  v_threshold INTEGER;
  v_badge_type VARCHAR(50);
  v_badge_name VARCHAR(100);
  v_badge_description TEXT;
  v_badge_icon VARCHAR(50);
BEGIN
  -- Get user's total completed tasks
  SELECT total_tasks_completed, current_level
  INTO v_total_tasks, v_current_level
  FROM profiles 
  WHERE id = p_user_id;
  
  -- Get level threshold
  SELECT CAST(config_value AS INTEGER) INTO v_threshold
  FROM gamification_config 
  WHERE config_key = 'level_threshold';
  
  -- Calculate new level
  v_new_level := FLOOR(v_total_tasks / v_threshold) + 1;
  
  -- Update level if changed
  IF v_new_level != v_current_level THEN
    UPDATE profiles 
    SET current_level = v_new_level
    WHERE id = p_user_id;
  END IF;
  
  -- Award badges based on level thresholds
  -- Newbie badge (Level 1+)
  IF v_new_level >= 1 THEN
    SELECT CAST(config_value AS INTEGER), badge_name, badge_description, badge_icon
    INTO v_badge_type, v_badge_name, v_badge_description, v_badge_icon
    FROM gamification_config 
    WHERE config_key = 'newbie_threshold';
    
    INSERT INTO user_badges (user_id, badge_type, badge_name, badge_description, badge_icon)
    VALUES (p_user_id, 'newbie', 'Newbie', 'Welcome to Earnify! Complete your first task.', 'award')
    ON CONFLICT (user_id, badge_type) DO NOTHING;
  END IF;
  
  -- Regular badge (Level 5+)
  IF v_new_level >= 5 THEN
    INSERT INTO user_badges (user_id, badge_type, badge_name, badge_description, badge_icon)
    VALUES (p_user_id, 'regular', 'Regular', 'You''re becoming a regular earner!', 'star')
    ON CONFLICT (user_id, badge_type) DO NOTHING;
  END IF;
  
  -- Achiever badge (Level 10+)
  IF v_new_level >= 10 THEN
    INSERT INTO user_badges (user_id, badge_type, badge_name, badge_description, badge_icon)
    VALUES (p_user_id, 'achiever', 'Achiever', 'You''re achieving great things!', 'trophy')
    ON CONFLICT (user_id, badge_type) DO NOTHING;
  END IF;
  
  -- Master badge (Level 20+)
  IF v_new_level >= 20 THEN
    INSERT INTO user_badges (user_id, badge_type, badge_name, badge_description, badge_icon)
    VALUES (p_user_id, 'master', 'Master', 'You''ve mastered the art of earning!', 'crown')
    ON CONFLICT (user_id, badge_type) DO NOTHING;
  END IF;
  
  -- Legend badge (Level 50+)
  IF v_new_level >= 50 THEN
    INSERT INTO user_badges (user_id, badge_type, badge_name, badge_description, badge_icon)
    VALUES (p_user_id, 'legend', 'Legend', 'You''re a true legend in the Earnify community!', 'gem')
    ON CONFLICT (user_id, badge_type) DO NOTHING;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to get user gamification stats
CREATE OR REPLACE FUNCTION get_user_gamification_stats(
  p_user_id UUID
) RETURNS TABLE(
  streak_count INTEGER,
  last_login_date DATE,
  current_level INTEGER,
  total_tasks_completed INTEGER,
  total_earned_points INTEGER,
  badges JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.streak_count,
    p.last_login_date,
    p.current_level,
    p.total_tasks_completed,
    p.total_earned_points,
    COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'badge_type', ub.badge_type,
          'badge_name', ub.badge_name,
          'badge_description', ub.badge_description,
          'badge_icon', ub.badge_icon,
          'earned_at', ub.earned_at
        )
      ),
      '[]'::jsonb
    ) as badges
  FROM profiles p
  LEFT JOIN user_badges ub ON p.id = ub.user_id AND ub.is_active = TRUE
  WHERE p.id = p_user_id
  GROUP BY p.id, p.streak_count, p.last_login_date, p.current_level, p.total_tasks_completed, p.total_earned_points;
END;
$$ LANGUAGE plpgsql;

-- Function to get gamification configuration
CREATE OR REPLACE FUNCTION get_gamification_config() 
RETURNS TABLE(
  config_key VARCHAR(100),
  config_value TEXT,
  description TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT config_key, config_value, description
  FROM gamification_config
  ORDER BY config_key;
END;
$$ LANGUAGE plpgsql;