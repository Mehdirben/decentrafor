-- Fix RLS policies for the pdfs table

-- First, drop existing policies if they exist
DROP POLICY IF EXISTS "PDFs are publicly readable" ON pdfs;
DROP POLICY IF EXISTS "PDFs can be inserted by anyone" ON pdfs;
DROP POLICY IF EXISTS "PDFs can be updated by anyone" ON pdfs;
DROP POLICY IF EXISTS "PDFs can be deleted by anyone" ON pdfs;

-- Disable RLS temporarily to clean up
ALTER TABLE pdfs DISABLE ROW LEVEL SECURITY;

-- Re-enable RLS
ALTER TABLE pdfs ENABLE ROW LEVEL SECURITY;

-- Create comprehensive policies for public access
CREATE POLICY "Enable read access for all users" ON pdfs
    FOR SELECT USING (true);

CREATE POLICY "Enable insert access for all users" ON pdfs
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable update access for all users" ON pdfs
    FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY "Enable delete access for all users" ON pdfs
    FOR DELETE USING (true);

-- Verify the policies are working
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'pdfs';

-- Also ensure the storage bucket exists and has proper policies
-- Run this in the Supabase dashboard SQL editor:
-- INSERT INTO storage.buckets (id, name, public) VALUES ('pdfs', 'pdfs', true)
-- ON CONFLICT (id) DO NOTHING;

-- Create storage policies for the bucket
CREATE POLICY "Give users access to own folder" ON storage.objects
    FOR SELECT USING (bucket_id = 'pdfs');

CREATE POLICY "Give users access to upload files" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'pdfs');

CREATE POLICY "Give users access to update files" ON storage.objects
    FOR UPDATE USING (bucket_id = 'pdfs');

CREATE POLICY "Give users access to delete files" ON storage.objects
    FOR DELETE USING (bucket_id = 'pdfs');
