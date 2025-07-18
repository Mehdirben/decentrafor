-- Alternative: Comprehensive PDF permissions setup
-- This script provides a balanced approach:
-- - Anyone can view PDFs (public read access)
-- - Anyone can insert PDFs (public upload access) 
-- - Only admins can update/delete PDFs (admin management)

-- Drop all existing PDF policies to start fresh
DROP POLICY IF EXISTS "PDFs are publicly readable" ON pdfs;
DROP POLICY IF EXISTS "PDFs can be inserted by admin users" ON pdfs;
DROP POLICY IF EXISTS "PDFs can be updated by admin users" ON pdfs;
DROP POLICY IF EXISTS "PDFs can be deleted by admin users" ON pdfs;
DROP POLICY IF EXISTS "Anyone can insert PDFs" ON pdfs;
DROP POLICY IF EXISTS "Authenticated users can insert PDFs" ON pdfs;
DROP POLICY IF EXISTS "Admins can delete any PDF" ON pdfs;

-- Create comprehensive policies
-- 1. Everyone can read PDFs (public access)
CREATE POLICY "PDFs are publicly readable" ON pdfs
    FOR SELECT USING (true);

-- 2. Anyone can upload PDFs (allows users to contribute content)
CREATE POLICY "Anyone can upload PDFs" ON pdfs
    FOR INSERT WITH CHECK (true);

-- 3. Only admins can update PDFs (admin management)
CREATE POLICY "Only admins can update PDFs" ON pdfs
    FOR UPDATE USING (is_admin()) WITH CHECK (is_admin());

-- 4. Only admins can delete PDFs (admin management)
CREATE POLICY "Only admins can delete PDFs" ON pdfs
    FOR DELETE USING (is_admin());

-- Verify the new policies
SELECT 'Comprehensive PDF permissions applied successfully' AS status;
SELECT policyname, cmd, qual FROM pg_policies WHERE tablename = 'pdfs' ORDER BY cmd;
