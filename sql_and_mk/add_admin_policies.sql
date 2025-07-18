-- Add admin policies for forum content moderation
-- This script adds Row Level Security policies that allow admins to delete forum content

-- Function to check if a user is an admin
CREATE OR REPLACE FUNCTION is_admin(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if current user's email is in admin_users table
    RETURN EXISTS (
        SELECT 1 FROM admin_users 
        WHERE email = (SELECT email FROM auth.users WHERE id = user_id)
        AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing admin policies if they exist
DROP POLICY IF EXISTS "Admins can delete any category" ON forum_categories;
DROP POLICY IF EXISTS "Admins can delete any topic" ON forum_topics;
DROP POLICY IF EXISTS "Admins can delete any post" ON forum_posts;
DROP POLICY IF EXISTS "Admins can update any category" ON forum_categories;
DROP POLICY IF EXISTS "Admins can update any topic" ON forum_topics;
DROP POLICY IF EXISTS "Admins can update any post" ON forum_posts;

-- Add admin delete policy for forum_categories
CREATE POLICY "Admins can delete any category" ON forum_categories
    FOR DELETE USING (is_admin(auth.uid()));

-- Add admin delete policy for forum_topics  
CREATE POLICY "Admins can delete any topic" ON forum_topics
    FOR DELETE USING (is_admin(auth.uid()));

-- Add admin delete policy for forum_posts
CREATE POLICY "Admins can delete any post" ON forum_posts
    FOR DELETE USING (is_admin(auth.uid()));

-- Add admin update policies as well (for content moderation)
CREATE POLICY "Admins can update any category" ON forum_categories
    FOR UPDATE USING (is_admin(auth.uid()));

CREATE POLICY "Admins can update any topic" ON forum_topics
    FOR UPDATE USING (is_admin(auth.uid()));

CREATE POLICY "Admins can update any post" ON forum_posts
    FOR UPDATE USING (is_admin(auth.uid()));
