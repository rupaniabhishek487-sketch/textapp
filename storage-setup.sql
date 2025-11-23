-- Verification Jobs Table for Audio Processing
CREATE TABLE IF NOT EXISTS verification_jobs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  submission_id TEXT NOT NULL,
  audio_url TEXT NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  similarity_score NUMERIC,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for verification jobs
CREATE INDEX IF NOT EXISTS idx_verification_jobs_status ON verification_jobs(status);
CREATE INDEX IF NOT EXISTS idx_verification_jobs_user_id ON verification_jobs(user_id);
CREATE INDEX IF NOT EXISTS idx_verification_jobs_task_id ON verification_jobs(task_id);

-- RLS for verification jobs
ALTER TABLE verification_jobs ENABLE ROW LEVEL SECURITY;

-- Policies for verification jobs
CREATE POLICY "Users can view own verification jobs" ON verification_jobs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins can view all verification jobs" ON verification_jobs FOR SELECT USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
);
CREATE POLICY "System can create verification jobs" ON verification_jobs FOR INSERT WITH CHECK (true);
CREATE POLICY "System can update verification jobs" ON verification_jobs FOR UPDATE WITH CHECK (true);

-- Trigger for updated_at
CREATE TRIGGER handle_verification_jobs_updated_at BEFORE UPDATE ON verification_jobs FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Storage Bucket for Audio Submissions
-- Run this in Supabase Dashboard:
-- INSERT INTO storage.buckets (id, name, public) VALUES ('audio-submissions', 'audio-submissions', true);

-- Storage Policies for Audio Submissions
-- Run these in Supabase Dashboard:
-- POLICY "Users can upload their own audio" ON storage.objects FOR INSERT WITH CHECK (
--   bucket_id = 'audio-submissions' AND 
--   auth.role() = 'authenticated' AND 
--   (storage.foldername(name))[1] = auth.uid()::text
-- );

-- POLICY "Users can view their own audio" ON storage.objects FOR SELECT USING (
--   bucket_id = 'audio-submissions' AND 
--   auth.role() = 'authenticated' AND 
--   (storage.foldername(name))[1] = auth.uid()::text
-- );

-- POLICY "Admins can view all audio" ON storage.objects FOR SELECT USING (
--   bucket_id = 'audio-submissions' AND 
--   EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
-- );