-- Add admin-only policies for PDF management
-- This script restricts PDF deletion to admins only while keeping other operations public

-- First, ensure the is_admin function exists (run add_admin_policies.sql first if needed)

-- Drop existing PDF delete policy
DROP POLICY IF EXISTS "pdfs_delete_policy" ON pdfs;

-- Create admin-only delete policy for PDFs
CREATE POLICY "Admins can delete any PDF" ON pdfs
    FOR DELETE USING (is_admin(auth.uid()));

-- Optional: Also restrict PDF updates to admins
-- Uncomment the following lines if you want only admins to update PDFs
-- DROP POLICY IF EXISTS "pdfs_update_policy" ON pdfs;
-- CREATE POLICY "Admins can update any PDF" ON pdfs
--     FOR UPDATE USING (is_admin(auth.uid())) WITH CHECK (is_admin(auth.uid()));

-- Verify the policies
SELECT 'PDF admin policies created successfully' AS status;
SELECT policyname, cmd, qual FROM pg_policies WHERE tablename = 'pdfs' AND cmd = 'DELETE';
