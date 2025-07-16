-- Admin Authentication Setup for Supabase
-- Run this in your Supabase SQL Editor after setting up the main database

-- Enable auth schema access
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create admin_users table to track admin users
CREATE TABLE IF NOT EXISTS admin_users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    role TEXT NOT NULL DEFAULT 'admin',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on admin_users table
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Create policies for admin_users table
CREATE POLICY "Admin users are readable by authenticated users" ON admin_users
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Admin users can be inserted by authenticated users" ON admin_users
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Insert sample admin users (replace with your actual admin emails)
INSERT INTO admin_users (email, role) VALUES
    ('admin@decentrafor.com', 'admin'),
    ('mehdi@decentrafor.com', 'admin')
ON CONFLICT (email) DO NOTHING;

-- Create function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM admin_users
        WHERE email = auth.jwt() ->> 'email'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update RLS policies for pdfs table to require admin access for modification
-- First, drop existing policies
DROP POLICY IF EXISTS "PDFs are publicly readable" ON pdfs;
DROP POLICY IF EXISTS "PDFs can be inserted by anyone" ON pdfs;
DROP POLICY IF EXISTS "PDFs can be updated by anyone" ON pdfs;
DROP POLICY IF EXISTS "PDFs can be deleted by anyone" ON pdfs;

-- Create new policies with admin restrictions
CREATE POLICY "PDFs are publicly readable" ON pdfs
    FOR SELECT USING (true);

CREATE POLICY "PDFs can be inserted by admin users" ON pdfs
    FOR INSERT WITH CHECK (is_admin());

CREATE POLICY "PDFs can be updated by admin users" ON pdfs
    FOR UPDATE USING (is_admin());

CREATE POLICY "PDFs can be deleted by admin users" ON pdfs
    FOR DELETE USING (is_admin());

-- Create a trigger to automatically update the updated_at column on admin_users
CREATE OR REPLACE FUNCTION update_admin_users_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_admin_users_updated_at BEFORE UPDATE ON admin_users
    FOR EACH ROW EXECUTE FUNCTION update_admin_users_updated_at();

-- Instructions:
-- 1. After running this script, you need to create admin users in Supabase Auth
-- 2. Go to Authentication > Users in your Supabase dashboard
-- 3. Create users with the emails you specified in the admin_users table
-- 4. Make sure to use strong passwords
-- 5. Test the login functionality in your Flutter app

-- Optional: Create a view for easier admin management
CREATE OR REPLACE VIEW admin_user_info AS
SELECT 
    au.id,
    au.email,
    au.role,
    au.created_at,
    au.updated_at,
    CASE 
        WHEN auth_users.id IS NOT NULL THEN 'Active'
        ELSE 'Inactive'
    END as auth_status
FROM admin_users au
LEFT JOIN auth.users auth_users ON au.email = auth_users.email;

-- Grant access to the view
GRANT SELECT ON admin_user_info TO authenticated;
