-- Create the pdfs table
CREATE TABLE pdfs (
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

-- Create an index for faster searches
CREATE INDEX idx_pdfs_title ON pdfs USING GIN (to_tsvector('english', title));
CREATE INDEX idx_pdfs_description ON pdfs USING GIN (to_tsvector('english', description));
CREATE INDEX idx_pdfs_category ON pdfs (category);
CREATE INDEX idx_pdfs_created_at ON pdfs (created_at);

-- Create a storage bucket for PDFs (run this in the Supabase dashboard)
-- INSERT INTO storage.buckets (id, name, public) VALUES ('pdfs', 'pdfs', true);

-- Enable Row Level Security (RLS)
ALTER TABLE pdfs ENABLE ROW LEVEL SECURITY;

-- Create policies for public access (adjust as needed for your use case)
CREATE POLICY "PDFs are publicly readable" ON pdfs
    FOR SELECT USING (true);

CREATE POLICY "PDFs can be inserted by anyone" ON pdfs
    FOR INSERT WITH CHECK (true);

CREATE POLICY "PDFs can be updated by anyone" ON pdfs
    FOR UPDATE USING (true);

CREATE POLICY "PDFs can be deleted by anyone" ON pdfs
    FOR DELETE USING (true);

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create a trigger to automatically update the updated_at column
CREATE TRIGGER update_pdfs_updated_at BEFORE UPDATE ON pdfs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
