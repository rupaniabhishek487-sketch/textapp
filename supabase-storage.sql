-- Storage bucket and policies setup (run after main schema)

-- Create storage bucket for audio uploads
INSERT INTO storage.buckets (id, name, public) 
VALUES ('audio-uploads', 'audio-uploads', false)
ON CONFLICT (id) DO NOTHING;

-- Create function to handle increment operations
CREATE OR REPLACE FUNCTION increment(x numeric) RETURNS numeric AS $$
BEGIN
  RETURN x;
END;
$$ LANGUAGE plpgsql;

-- Sample data for testing
INSERT INTO tasks (title, description, task_type, reward_points, active) VALUES
('Simple Typing Task', 'Type the given text accurately to earn points', 'typing', 50, true),
('Audio Transcription', 'Transcribe the provided audio file', 'transcription', 100, true),
('Survey Completion', 'Complete a short survey about your preferences', 'survey', 30, true)
ON CONFLICT DO NOTHING;