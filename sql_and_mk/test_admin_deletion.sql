-- Test admin functionality
-- Run this in Supabase SQL Editor to debug admin issues

-- 1. Check if admin_users table exists and has data
SELECT 'Admin Users Table:' as info;
SELECT * FROM admin_users;

-- 2. Check current authenticated user (if any)
SELECT 'Current Auth User:' as info;
SELECT id, email FROM auth.users WHERE id = auth.uid();

-- 3. Test the is_admin function with current user
SELECT 'Is Admin Test:' as info;
SELECT is_admin(auth.uid()) as is_current_user_admin;

-- 4. Check if current user's email exists in admin_users
SELECT 'Email Check:' as info;
SELECT 
    auth_user.email as auth_email,
    admin_user.email as admin_email,
    admin_user.role
FROM auth.users auth_user
LEFT JOIN admin_users admin_user ON auth_user.email = admin_user.email
WHERE auth_user.id = auth.uid();

-- 5. Check PDF table policies
SELECT 'PDF Policies:' as info;
SELECT policyname, cmd, qual FROM pg_policies 
WHERE tablename = 'pdfs' AND cmd = 'DELETE';

-- 6. Test PDF deletion manually (replace 'your-pdf-id' with actual PDF ID)
-- SELECT 'Testing PDF Deletion:' as info;
-- DELETE FROM pdfs WHERE id = 'your-pdf-id';
-- Uncomment above lines and replace with actual PDF ID to test
