-- Test script to verify admin functionality
-- Run this to check if the admin detection is working

-- Test 1: Check if the is_admin function exists and works
SELECT is_admin(auth.uid()) AS am_i_admin;

-- Test 2: Check current user ID
SELECT auth.uid() AS current_user_id;

-- Test 3: Check if current user is in admin_users table
SELECT EXISTS(SELECT 1 FROM admin_users WHERE id = auth.uid()) AS in_admin_table;

-- Test 4: List all admin users
SELECT * FROM admin_users;

-- Test 5: Check current JWT metadata
SELECT auth.jwt() AS current_jwt;

-- Test 6: Try to manually check RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('forum_categories', 'forum_topics', 'forum_posts');
