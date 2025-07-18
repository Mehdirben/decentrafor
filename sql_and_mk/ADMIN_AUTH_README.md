# Admin Authentication Setup

This document explains how to set up admin authentication for the storage management features.

## Overview

The storage management screen is now protected and requires admin authentication. Only users with admin privileges can:
- Upload sample PDFs
- Delete PDFs
- Test database and storage connections
- View storage information

## Setup Instructions

### 1. Database Setup

1. Run the SQL script in your Supabase SQL Editor:
   ```bash
   # Copy the contents of admin_auth_setup.sql and run it in Supabase SQL Editor
   ```

2. This will create:
   - `admin_users` table to track admin users
   - Proper RLS policies for admin access
   - Helper functions for admin checking

### 2. Create Admin Users

1. Go to your Supabase dashboard
2. Navigate to Authentication > Users
3. Click "Add user"
4. Create users with the emails you want to be admins:
   - `admin@decentrafor.com`
   - `mehdi@decentrafor.com`
   - Add more as needed

5. Make sure to use strong passwords for these accounts

### 3. Update Admin Emails

If you want to add more admin emails, you can either:

**Option A: Update the database**
```sql
INSERT INTO admin_users (email, role) VALUES
    ('new-admin@example.com', 'admin');
```

**Option B: Update the fallback list in code**
Edit `lib/services/auth_service.dart` and add emails to the `adminEmails` array.

## How It Works

1. **Authentication Flow:**
   - User clicks on Storage Management
   - System checks if user is logged in and is admin
   - If not authenticated, shows login screen
   - If authenticated but not admin, shows access denied
   - If authenticated and admin, shows storage management

2. **Admin Checking:**
   - First checks user metadata for admin role
   - Then checks `admin_users` table in database
   - Falls back to hardcoded admin emails if database check fails

3. **Security:**
   - Uses Supabase Auth for authentication
   - Row Level Security (RLS) policies protect admin operations
   - Admin status is verified on every storage operation

## Usage

1. **For Regular Users:**
   - Storage Management button will require login
   - If not admin, will show access denied

2. **For Admin Users:**
   - Click Storage Management
   - Enter admin credentials
   - Access granted to all storage features
   - Logout button available in app bar

## Features Added

- **Admin Login Screen:** Beautiful, modern login interface
- **Authentication Service:** Handles login/logout and admin checking
- **Protected Routes:** Storage screen requires admin authentication
- **Session Management:** Maintains login state across app usage
- **Logout Functionality:** Easy logout from storage screen

## Security Notes

- Admin credentials are managed through Supabase Auth
- Database operations are protected by RLS policies
- Admin status is verified server-side
- Session tokens are managed securely by Supabase

## Troubleshooting

1. **Can't login:** Check if user exists in Supabase Auth
2. **Access denied:** Verify user email is in `admin_users` table
3. **Database errors:** Check if `admin_auth_setup.sql` was run correctly
4. **RLS errors:** Ensure policies are properly applied

## Future Enhancements

- Role-based permissions (super admin, admin, moderator)
- User management interface
- Activity logging
- Password reset functionality
- Multi-factor authentication
