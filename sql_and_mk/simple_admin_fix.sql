-- Simple admin policies fix - matches existing admin_users table structure
-- Run this script to fix admin deletion permissions

-- Drop and recreate the is_admin function to match actual table structure
DROP FUNCTION IF EXISTS is_admin(UUID);

-- Simple admin check function that works with current auth context
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if current authenticated user's email is in admin_users table
    RETURN EXISTS (
        SELECT 1 FROM admin_users 
        WHERE email = auth.jwt() ->> 'email'
        AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing admin policies
DROP POLICY IF EXISTS "Admins can delete any category" ON forum_categories;
DROP POLICY IF EXISTS "Admins can delete any topic" ON forum_topics;
DROP POLICY IF EXISTS "Admins can delete any post" ON forum_posts;
DROP POLICY IF EXISTS "Admins can update any category" ON forum_categories;
DROP POLICY IF EXISTS "Admins can update any topic" ON forum_topics;
DROP POLICY IF EXISTS "Admins can update any post" ON forum_posts;

-- Create admin policies using the simplified function
CREATE POLICY "Admins can delete any category" ON forum_categories
    FOR DELETE USING (is_admin());

CREATE POLICY "Admins can delete any topic" ON forum_topics
    FOR DELETE USING (is_admin());

CREATE POLICY "Admins can delete any post" ON forum_posts
    FOR DELETE USING (is_admin());

CREATE POLICY "Admins can update any category" ON forum_categories
    FOR UPDATE USING (is_admin());

CREATE POLICY "Admins can update any topic" ON forum_topics
    FOR UPDATE USING (is_admin());

CREATE POLICY "Admins can update any post" ON forum_posts
    FOR UPDATE USING (is_admin());
