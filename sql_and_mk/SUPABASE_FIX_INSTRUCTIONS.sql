-- STEP-BY-STEP INSTRUCTIONS TO FIX RLS POLICIES
-- Run these commands in your Supabase Dashboard > SQL Editor

-- 1. First, check if the table exists and has data
SELECT COUNT(*) FROM pdfs;

-- 2. Check current policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'pdfs';

-- 3. Drop all existing policies to start fresh
DROP POLICY IF EXISTS "PDFs are publicly readable" ON pdfs;
DROP POLICY IF EXISTS "PDFs can be inserted by anyone" ON pdfs;
DROP POLICY IF EXISTS "PDFs can be updated by anyone" ON pdfs;
DROP POLICY IF EXISTS "PDFs can be deleted by anyone" ON pdfs;
DROP POLICY IF EXISTS "Enable read access for all users" ON pdfs;
DROP POLICY IF EXISTS "Enable insert access for all users" ON pdfs;
DROP POLICY IF EXISTS "Enable update access for all users" ON pdfs;
DROP POLICY IF EXISTS "Enable delete access for all users" ON pdfs;

-- 4. Temporarily disable RLS to clean up
ALTER TABLE pdfs DISABLE ROW LEVEL SECURITY;

-- 5. Re-enable RLS
ALTER TABLE pdfs ENABLE ROW LEVEL SECURITY;

-- 6. Create new, working policies
CREATE POLICY "pdfs_select_policy" ON pdfs
    FOR SELECT USING (true);

CREATE POLICY "pdfs_insert_policy" ON pdfs
    FOR INSERT WITH CHECK (true);

CREATE POLICY "pdfs_update_policy" ON pdfs
    FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY "pdfs_delete_policy" ON pdfs
    FOR DELETE USING (true);

-- 7. Test the policies work by inserting a test record
INSERT INTO pdfs (title, description, file_name, file_url, file_size, category, tags)
VALUES ('Test PDF', 'This is a test', 'test.pdf', 'https://example.com/test.pdf', 1024, 'Test', ARRAY['test']);

-- 8. If successful, delete the test record
DELETE FROM pdfs WHERE title = 'Test PDF' AND description = 'This is a test';

-- 9. Create storage bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public) 
VALUES ('pdfs', 'pdfs', true)
ON CONFLICT (id) DO NOTHING;

-- 10. Create storage policies for the bucket
CREATE POLICY "storage_pdfs_select" ON storage.objects
    FOR SELECT USING (bucket_id = 'pdfs');

CREATE POLICY "storage_pdfs_insert" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'pdfs');

CREATE POLICY "storage_pdfs_update" ON storage.objects
    FOR UPDATE USING (bucket_id = 'pdfs');

CREATE POLICY "storage_pdfs_delete" ON storage.objects
    FOR DELETE USING (bucket_id = 'pdfs');

-- 11. Verify everything is working
SELECT 'Policies created successfully' AS status;
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'pdfs';
