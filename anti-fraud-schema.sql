-- Anti-Fraud System Schema and Functions for Earnify

-- Device fingerprints table to track devices and IPs
CREATE TABLE IF NOT EXISTS device_fingerprints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  fingerprint_hash VARCHAR(255) NOT NULL,
  ip_address INET,
  user_agent TEXT,
  last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_suspicious BOOLEAN DEFAULT FALSE,
  UNIQUE(user_id, fingerprint_hash)
);

-- Rate limiting table
CREATE TABLE IF NOT EXISTS rate_limits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  action_type VARCHAR(50) NOT NULL, -- 'text_submission', 'audio_submission'
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'::jsonb
);

-- Fraud alerts table
CREATE TABLE IF NOT EXISTS fraud_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  alert_type VARCHAR(100) NOT NULL, -- 'duplicate_device', 'rapid_submissions', 'suspicious_ip'
  severity VARCHAR(20) DEFAULT 'medium', -- 'low', 'medium', 'high'
  description TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  status VARCHAR(20) DEFAULT 'active', -- 'active', 'resolved', 'dismissed'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  resolved_at TIMESTAMP WITH TIME ZONE
);

-- User suspensions table
CREATE TABLE IF NOT EXISTS user_suspensions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  suspended_by UUID REFERENCES profiles(id),
  suspended_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  lifted_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT TRUE,
  notes TEXT
);

-- Add suspension status to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_suspended BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS suspended_at TIMESTAMP WITH TIME ZONE;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_device_fingerprints_user_id ON device_fingerprints(user_id);
CREATE INDEX IF NOT EXISTS idx_device_fingerprints_fingerprint_hash ON device_fingerprints(fingerprint_hash);
CREATE INDEX IF NOT EXISTS idx_device_fingerprints_ip_address ON device_fingerprints(ip_address);
CREATE INDEX IF NOT EXISTS idx_rate_limits_user_id ON rate_limits(user_id);
CREATE INDEX IF NOT EXISTS idx_rate_limits_timestamp ON rate_limits(timestamp);
CREATE INDEX IF NOT EXISTS idx_fraud_alerts_user_id ON fraud_alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_fraud_alerts_status ON fraud_alerts(status);
CREATE INDEX IF NOT EXISTS idx_user_suspensions_user_id ON user_suspensions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_suspensions_is_active ON user_suspensions(is_active);

-- Function to record device fingerprint
CREATE OR REPLACE FUNCTION record_device_fingerprint(
  p_user_id UUID,
  p_fingerprint_hash VARCHAR(255),
  p_ip_address INET,
  p_user_agent TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  existing_fingerprint RECORD;
  suspicious_count INTEGER;
BEGIN
  -- Check if this fingerprint already exists for this user
  SELECT * INTO existing_fingerprint 
  FROM device_fingerprints 
  WHERE user_id = p_user_id AND fingerprint_hash = p_fingerprint_hash;
  
  IF FOUND THEN
    -- Update last seen
    UPDATE device_fingerprints 
    SET last_seen = NOW(), ip_address = p_ip_address, user_agent = p_user_agent
    WHERE id = existing_fingerprint.id;
  ELSE
    -- Insert new fingerprint
    INSERT INTO device_fingerprints (user_id, fingerprint_hash, ip_address, user_agent)
    VALUES (p_user_id, p_fingerprint_hash, p_ip_address, p_user_agent);
  END IF;
  
  -- Check for suspicious activity (same fingerprint used by multiple users)
  SELECT COUNT(*) INTO suspicious_count
  FROM device_fingerprints 
  WHERE fingerprint_hash = p_fingerprint_hash 
  AND user_id != p_user_id
  AND last_seen > NOW() - INTERVAL '24 hours';
  
  IF suspicious_count > 0 THEN
    -- Create fraud alert for duplicate device
    INSERT INTO fraud_alerts (user_id, alert_type, severity, description, metadata)
    VALUES (
      p_user_id,
      'duplicate_device',
      'high',
      'Device fingerprint used by multiple accounts',
      jsonb_build_object('fingerprint_hash', p_fingerprint_hash, 'other_users_count', suspicious_count)
    );
  END IF;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to check rate limits
CREATE OR REPLACE FUNCTION check_rate_limit(
  p_user_id UUID,
  p_action_type VARCHAR(50),
  p_time_window_seconds INTEGER,
  p_max_attempts INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
  attempt_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO attempt_count
  FROM rate_limits 
  WHERE user_id = p_user_id 
  AND action_type = p_action_type
  AND timestamp > NOW() - INTERVAL '1 second' * p_time_window_seconds;
  
  RETURN attempt_count < p_max_attempts;
END;
$$ LANGUAGE plpgsql;

-- Function to record rate limit attempt
CREATE OR REPLACE FUNCTION record_rate_limit_attempt(
  p_user_id UUID,
  p_action_type VARCHAR(50),
  p_metadata JSONB DEFAULT '{}'::jsonb
) RETURNS VOID AS $$
BEGIN
  INSERT INTO rate_limits (user_id, action_type, metadata)
  VALUES (p_user_id, p_action_type, p_metadata);
END;
$$ LANGUAGE plpgsql;

-- Function to check daily submission limit
CREATE OR REPLACE FUNCTION check_daily_submission_limit(
  p_user_id UUID,
  p_max_daily INTEGER DEFAULT 50
) RETURNS BOOLEAN AS $$
DECLARE
  daily_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO daily_count
  FROM rate_limits 
  WHERE user_id = p_user_id 
  AND action_type IN ('text_submission', 'audio_submission')
  AND timestamp >= CURRENT_DATE;
  
  RETURN daily_count < p_max_daily;
END;
$$ LANGUAGE plpgsql;

-- Function to check if user is suspended
CREATE OR REPLACE FUNCTION is_user_suspended(p_user_id UUID) RETURNS BOOLEAN AS $$
DECLARE
  suspension_active BOOLEAN;
BEGIN
  SELECT COALESCE(is_suspended, FALSE) INTO suspension_active
  FROM profiles 
  WHERE id = p_user_id;
  
  RETURN suspension_active;
END;
$$ LANGUAGE plpgsql;

-- Function to suspend user
CREATE OR REPLACE FUNCTION suspend_user(
  p_user_id UUID,
  p_reason TEXT,
  p_suspended_by UUID
) RETURNS BOOLEAN AS $$
BEGIN
  -- Update profile
  UPDATE profiles 
  SET is_suspended = TRUE, suspended_at = NOW()
  WHERE id = p_user_id;
  
  -- Create suspension record
  INSERT INTO user_suspensions (user_id, reason, suspended_by)
  VALUES (p_user_id, p_reason, p_suspended_by);
  
  -- Create fraud alert
  INSERT INTO fraud_alerts (user_id, alert_type, severity, description, metadata)
  VALUES (
    p_user_id,
    'user_suspended',
    'high',
    'User suspended by administrator',
    jsonb_build_object('reason', p_reason, 'suspended_by', p_suspended_by)
  );
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to lift user suspension
CREATE OR REPLACE FUNCTION lift_user_suspension(
  p_user_id UUID
) RETURNS BOOLEAN AS $$
BEGIN
  -- Update profile
  UPDATE profiles 
  SET is_suspended = FALSE, suspended_at = NULL
  WHERE id = p_user_id;
  
  -- Update suspension record
  UPDATE user_suspensions 
  SET is_active = FALSE, lifted_at = NOW()
  WHERE user_id = p_user_id AND is_active = TRUE;
  
  -- Resolve fraud alerts
  UPDATE fraud_alerts 
  SET status = 'resolved', resolved_at = NOW()
  WHERE user_id = p_user_id AND status = 'active';
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to check account age for payout eligibility
CREATE OR REPLACE FUNCTION is_payout_eligible(p_user_id UUID) RETURNS BOOLEAN AS $$
DECLARE
  account_age_hours NUMERIC;
BEGIN
  SELECT EXTRACT(EPOCH FROM (NOW() - created_at)) / 3600 INTO account_age_hours
  FROM profiles 
  WHERE id = p_user_id;
  
  RETURN account_age_hours >= 48;
END;
$$ LANGUAGE plpgsql;

-- Function to get suspicious users for admin
CREATE OR REPLACE FUNCTION get_suspicious_users() 
RETURNS TABLE(
  user_id UUID,
  username VARCHAR(255),
  email VARCHAR(255),
  is_suspended BOOLEAN,
  alert_count BIGINT,
  latest_alert_type VARCHAR(100),
  latest_severity VARCHAR(20),
  device_count BIGINT,
  ip_addresses TEXT[]
) AS $$
BEGIN
  RETURN QUERY
  WITH user_alerts AS (
    SELECT 
      fa.user_id,
      COUNT(*) as alert_count,
      fa.alert_type as latest_alert_type,
      fa.severity as latest_severity,
      ROW_NUMBER() OVER (PARTITION BY fa.user_id ORDER BY fa.created_at DESC) as rn
    FROM fraud_alerts fa
    WHERE fa.status = 'active'
    GROUP BY fa.user_id, fa.alert_type, fa.severity
  ),
  user_devices AS (
    SELECT 
      df.user_id,
      COUNT(*) as device_count,
      ARRAY_AGG(DISTINCT df.ip_address::TEXT) as ip_addresses
    FROM device_fingerprints df
    WHERE df.last_seen > NOW() - INTERVAL '7 days'
    GROUP BY df.user_id
  )
  SELECT 
    p.id,
    p.username,
    p.email,
    p.is_suspended,
    COALESCE(ua.alert_count, 0),
    ua.latest_alert_type,
    ua.latest_severity,
    COALESCE(ud.device_count, 0),
    COALESCE(ud.ip_addresses, ARRAY[]::TEXT[])
  FROM profiles p
  LEFT JOIN user_alerts ua ON p.id = ua.user_id AND ua.rn = 1
  LEFT JOIN user_devices ud ON p.id = ud.user_id
  WHERE (ua.alert_count > 0 OR ud.device_count > 1 OR p.is_suspended = TRUE)
  ORDER BY ua.alert_count DESC, p.is_suspended DESC;
END;
$$ LANGUAGE plpgsql;

-- Clean up old rate limit records (run daily)
CREATE OR REPLACE FUNCTION cleanup_old_rate_limits() RETURNS VOID AS $$
BEGIN
  DELETE FROM rate_limits 
  WHERE timestamp < NOW() - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql;

-- Clean up old device fingerprints (run monthly)
CREATE OR REPLACE FUNCTION cleanup_old_device_fingerprints() RETURNS VOID AS $$
BEGIN
  DELETE FROM device_fingerprints 
  WHERE last_seen < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;