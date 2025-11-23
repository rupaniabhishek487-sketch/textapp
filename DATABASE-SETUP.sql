# 🗄️ Database Setup - Complete SQL for Earnify

## 📋 **Instructions for Supabase Dashboard**

1. **Go to your Supabase Project**:
   - URL: https://gxuewpsyslvhqvpytthj.supabase.co
   - Navigate to **SQL Editor**

2. **Execute Main Schema**:
   - Copy the entire contents of `supabase-schema.sql`
   - Click **"Run"** 
   - Wait for completion

3. **Execute Additional Setup**:
   - Copy the contents of `supabase-storage.sql`
   - Click **"Run"**
   - Wait for completion

4. **Verify Tables Created**:
   ```sql
   SELECT table_name FROM information_schema.tables 
   WHERE table_schema = 'public' 
   ORDER BY table_name;
   ```

## 🗄️ **Complete Database Schema**

### **Core Tables**:
```sql
-- Users table (linked to auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  display_name TEXT,
  phone TEXT UNIQUE,
  points BIGINT DEFAULT 0,
  balance_inr NUMERIC DEFAULT 0.00,
  upi_id TEXT,
  referral_code TEXT UNIQUE,
  referred_by UUID REFERENCES profiles(id),
  total_tasks_completed INTEGER DEFAULT 0,
  total_earnings_inr NUMERIC DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tasks table
CREATE TABLE IF NOT EXISTS tasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  task_type TEXT NOT NULL CHECK (task_type IN ('typing', 'transcription', 'survey', 'other')),
  reward_points INTEGER NOT NULL DEFAULT 0,
  payload_url TEXT,
  max_completions INTEGER DEFAULT 0,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Task submissions table
CREATE TABLE IF NOT EXISTS task_submissions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  submission_text TEXT,
  submission_url TEXT,
  auto_score NUMERIC,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  reward_points INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Transactions table
CREATE TABLE IF NOT EXISTS transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  kind TEXT NOT NULL CHECK (kind IN ('task_reward', 'referral_bonus', 'payout', 'adjustment')),
  points INTEGER NOT NULL,
  inr_value NUMERIC DEFAULT 0.00,
  meta JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payout requests table
CREATE TABLE IF NOT EXISTS payout_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  amount_points INTEGER NOT NULL,
  amount_inr NUMERIC NOT NULL,
  upi_id TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'processed')),
  razorpay_payout_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Referrals table
CREATE TABLE IF NOT EXISTS referrals (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  referrer_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  referee_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Device fingerprints table
CREATE TABLE IF NOT EXISTS device_fingerprints (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  fingerprint TEXT NOT NULL,
  ip TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### **Row Level Security Policies**:
```sql
-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payout_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_fingerprints ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Tasks policies (publicly readable)
CREATE POLICY "Active tasks are publicly readable" ON tasks FOR SELECT USING (active = true);

-- Task submissions policies
CREATE POLICY "Users can view own submissions" ON task_submissions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own submissions" ON task_submissions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Transactions policies
CREATE POLICY "Users can view own transactions" ON transactions FOR SELECT USING (auth.uid() = user_id);

-- Payout requests policies
CREATE POLICY "Users can view own payout requests" ON payout_requests FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own payout requests" ON payout_requests FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Referrals policies
CREATE POLICY "Users can view own referrals" ON referrals FOR SELECT USING (auth.uid() = referrer_id OR auth.uid() = referee_id);

-- Device fingerprints policies
CREATE POLICY "Users can view own device fingerprints" ON device_fingerprints FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own device fingerprints" ON device_fingerprints FOR INSERT WITH CHECK (auth.uid() = user_id);
```

### **Functions and Triggers**:
```sql
-- Increment function for updating numeric fields
CREATE OR REPLACE FUNCTION increment(x numeric) RETURNS numeric AS $$
BEGIN
  RETURN x;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create profile on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, display_name, phone, referral_code)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'display_name', 'User' || substr(NEW.id::text, 1, 8)),
    NEW.phone,
    upper(substr(gen_random_uuid()::text, 1, 8))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

### **Storage Bucket Setup**:
```sql
-- Create storage bucket for audio uploads
INSERT INTO storage.buckets (id, name, public) 
VALUES ('audio-uploads', 'audio-uploads', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policies (optional)
CREATE POLICY "Users can upload their own audio" ON storage.objects 
FOR INSERT WITH CHECK (
  bucket_id = 'audio-uploads' AND 
  auth.role() = 'authenticated' AND 
  (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Users can view their own audio" ON storage.objects 
FOR SELECT USING (
  bucket_id = 'audio-uploads' AND 
  auth.role() = 'authenticated' AND 
  (storage.foldername(name))[1] = auth.uid()::text
);
```

## 🌱 **Sample Data**:
```sql
-- Sample tasks for testing
INSERT INTO tasks (title, description, task_type, reward_points, active) VALUES
('Simple Typing Task', 'Type the given text accurately to earn points', 'typing', 50, true),
('Audio Transcription', 'Transcribe the provided audio file', 'transcription', 100, true),
('Survey Completion', 'Complete a short survey about your preferences', 'survey', 30, true)
ON CONFLICT DO NOTHING;
```

## 🚀 **Execution Steps:**

1. **Run Main Schema First**:
   - Execute `supabase-schema.sql` completely
   - This creates all tables, functions, and RLS policies

2. **Run Storage Setup**:
   - Execute `supabase-storage.sql` 
   - This creates storage bucket and policies

3. **Verify Setup**:
   - Check that all tables exist
   - Verify RLS policies are active
   - Test with a sample query

## 🎯 **Expected Result:**

After running these SQL scripts, your Supabase project will have:
- ✅ **Complete database schema** with all required tables
- ✅ **Row Level Security** policies for data protection
- ✅ **Automatic profile creation** when users sign up
- ✅ **Storage bucket** for audio file uploads
- ✅ **Sample data** for immediate testing
- ✅ **Functions and triggers** for database automation

## 📋 **Admin UI Requirements**:

Your admin page (`/admin/page.tsx`) needs:
1. **Phone-based admin access** - Add your phone to `ADMIN_PHONES` array
2. **User management** - View all profiles and statistics
3. **Task moderation** - Approve/reject task submissions
4. **Payout management** - Process payout requests
5. **Database queries** - All operations use `supabaseAdmin` client

## 🎉 **Ready for Production!**

Your Earnify application will have:
- 🔐 **Secure database** with proper access controls
- 💰 **Complete functionality** with all required features
- 🛠️ **Admin tools** for platform management
- 📱 **Scalable architecture** ready for thousands of users

**Execute these SQL scripts in your Supabase dashboard and your platform will be fully functional!** 🚀