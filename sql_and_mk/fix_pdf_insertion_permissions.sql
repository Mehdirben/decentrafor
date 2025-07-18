-- Fix PDF insertion permissions to allow all users to add PDFs
-- This script allows anyone to insert PDFs while keeping deletion restricted to admins

-- Drop the current admin-only insert policy
DROP POLICY IF EXISTS "PDFs can be inserted by admin users" ON pdfs;

-- Create a new policy that allows anyone to insert PDFs
-- You can choose one of the following options:

-- Option 1: Allow anyone (including anonymous users) to insert PDFs
CREATE POLICY "Anyone can insert PDFs" ON pdfs
    FOR INSERT WITH CHECK (true);

-- Option 2: Allow only authenticated users to insert PDFs (recommended)
-- Comment out Option 1 above and uncomment the following if you prefer authenticated users only:
-- CREATE POLICY "Authenticated users can insert PDFs" ON pdfs
--     FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Keep the existing policies for other operations:
-- - SELECT: Everyone can read PDFs (already exists)
-- - UPDATE: Only admins can update PDFs (already exists) 
-- - DELETE: Only admins can delete PDFs (already exists)

-- Verify the policies
SELECT 'PDF insertion permissions fixed successfully' AS status;
SELECT policyname, cmd, qual FROM pg_policies WHERE tablename = 'pdfs' ORDER BY cmd;
