-- First, make sure to run this in your Supabase SQL Editor:

-- Create the pdfs table
CREATE TABLE IF NOT EXISTS pdfs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    category TEXT NOT NULL,
    tags TEXT[] DEFAULT '{}',
    thumbnail_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_pdfs_title ON pdfs USING GIN (to_tsvector('english', title));
CREATE INDEX IF NOT EXISTS idx_pdfs_description ON pdfs USING GIN (to_tsvector('english', description));
CREATE INDEX IF NOT EXISTS idx_pdfs_category ON pdfs (category);
CREATE INDEX IF NOT EXISTS idx_pdfs_created_at ON pdfs (created_at);

-- Enable Row Level Security (RLS)
ALTER TABLE pdfs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "PDFs are publicly readable" ON pdfs;
DROP POLICY IF EXISTS "PDFs can be inserted by anyone" ON pdfs;
DROP POLICY IF EXISTS "PDFs can be updated by anyone" ON pdfs;
DROP POLICY IF EXISTS "PDFs can be deleted by anyone" ON pdfs;

-- Create policies for public access
CREATE POLICY "PDFs are publicly readable" ON pdfs FOR SELECT USING (true);
CREATE POLICY "PDFs can be inserted by anyone" ON pdfs FOR INSERT WITH CHECK (true);
CREATE POLICY "PDFs can be updated by anyone" ON pdfs FOR UPDATE USING (true);
CREATE POLICY "PDFs can be deleted by anyone" ON pdfs FOR DELETE USING (true);

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create a trigger to automatically update the updated_at column
DROP TRIGGER IF EXISTS update_pdfs_updated_at ON pdfs;
CREATE TRIGGER update_pdfs_updated_at BEFORE UPDATE ON pdfs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert test data
INSERT INTO pdfs (title, description, file_name, file_url, file_size, category, tags) VALUES
(
    'Flutter Development Guide',
    'A comprehensive guide to Flutter development covering widgets, state management, and best practices.',
    'flutter_guide.pdf',
    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    2450000,
    'Technology',
    ARRAY['flutter', 'development', 'guide']
),
(
    'Business Strategy 2024',
    'Annual business strategy document outlining goals, objectives, and key performance indicators.',
    'business_strategy_2024.pdf',
    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    1890000,
    'Business',
    ARRAY['strategy', 'business', '2024']
),
(
    'Introduction to Machine Learning',
    'Educational material covering the basics of machine learning algorithms and applications.',
    'ml_intro.pdf',
    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    3200000,
    'Education',
    ARRAY['machine learning', 'education', 'ai']
),
(
    'Health and Wellness Report',
    'Annual health and wellness report with statistics and recommendations for healthy living.',
    'health_wellness_2024.pdf',
    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    1560000,
    'Health',
    ARRAY['health', 'wellness', 'report']
),
(
    'Science Research Paper',
    'Research paper on renewable energy sources and their impact on climate change.',
    'renewable_energy_research.pdf',
    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    4100000,
    'Science',
    ARRAY['research', 'renewable energy', 'climate']
);
