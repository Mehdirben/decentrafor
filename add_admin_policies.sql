-- Add admin policies for forum content moderation
-- This script adds Row Level Security policies that allow admins to delete forum content

-- Function to check if a user is an admin
CREATE OR REPLACE FUNCTION is_admin(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if user is in admin_users table or has admin role in metadata
    RETURN EXISTS (
        SELECT 1 FROM admin_users WHERE id = user_id
    ) OR (
        SELECT COALESCE(
            (auth.jwt() ->> 'user_metadata' ->> 'role') = 'admin' OR
            (auth.jwt() ->> 'app_metadata' ->> 'role') = 'admin',
            false
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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
