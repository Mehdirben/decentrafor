-- ALTERNATIVE: Temporarily disable RLS for testing
-- Run this in Supabase Dashboard > SQL Editor if you want to test without RLS

-- WARNING: This makes your table publicly accessible without any restrictions
-- Only use this for testing purposes

ALTER TABLE pdfs DISABLE ROW LEVEL SECURITY;

-- You can re-enable it later with:
-- ALTER TABLE pdfs ENABLE ROW LEVEL SECURITY;

-- After testing, make sure to re-enable RLS and set proper policies
