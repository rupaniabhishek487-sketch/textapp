-- Sample Tasks for Earnify
INSERT INTO tasks (id, title, description, task_type, reward_points, active, created_at, updated_at) VALUES
('typing-1', 'Type the Quick Brown Fox', 'Type the classic pangram sentence: "The quick brown fox jumps over the lazy dog"', 'typing', 10, true, NOW(), NOW()),
('typing-2', 'Type Sample Business Text', 'Type this business text exactly as shown: "The quarterly report shows significant growth in user engagement and revenue metrics."', 'typing', 15, true, NOW(), NOW()),
('typing-3', 'Type Technical Documentation', 'Type this technical sentence: "The API endpoint supports RESTful operations with JSON request and response formats."', 'typing', 20, true, NOW(), NOW()),
('transcription-1', 'Transcribe Audio Interview', 'Listen to the provided audio file and transcribe the interview conversation accurately', 'transcription', 50, true, NOW(), NOW()),
('transcription-2', 'Transcribe Meeting Notes', 'Transcribe the business meeting audio file into text format', 'transcription', 40, true, NOW(), NOW()),
('survey-1', 'Complete User Experience Survey', 'Share your feedback about our platform and help us improve your experience', 'survey', 25, true, NOW(), NOW()),
('survey-2', 'Product Feedback Survey', 'Tell us about your experience with online earning platforms', 'survey', 30, true, NOW(), NOW());