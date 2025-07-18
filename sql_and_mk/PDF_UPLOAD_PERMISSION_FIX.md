# PDF Upload Permission Fix

## Issue
Non-admin users cannot add PDFs because the current database policies restrict PDF insertion to admin users only.

## Root Cause
The `admin_auth_setup.sql` script was applied, which includes this policy:
```sql
CREATE POLICY "PDFs can be inserted by admin users" ON pdfs
    FOR INSERT WITH CHECK (is_admin());
```

This restricts PDF uploads to admin users only.

## Solution
We need to modify the database policies to allow all users to upload PDFs while keeping admin-only restrictions for update/delete operations.

### Option 1: Quick Fix
Run the `fix_pdf_insertion_permissions.sql` script in your Supabase SQL Editor. This will:
- Remove the admin-only insert restriction
- Allow anyone to upload PDFs
- Keep admin-only restrictions for updates and deletions

### Option 2: Comprehensive Setup (Recommended)
Run the `comprehensive_pdf_permissions.sql` script in your Supabase SQL Editor. This provides:
- **Public read access**: Anyone can view PDFs
- **Public upload access**: Anyone can upload PDFs
- **Admin-only management**: Only admins can update/delete PDFs

## Implementation Steps

1. **Go to your Supabase Dashboard**
2. **Navigate to SQL Editor**
3. **Run one of the provided SQL scripts:**
   - `fix_pdf_insertion_permissions.sql` (quick fix)
   - `comprehensive_pdf_permissions.sql` (recommended)

4. **Test the upload functionality** in your Flutter app

## Verification
After running the script, you can verify the policies by running:
```sql
SELECT policyname, cmd, qual FROM pg_policies WHERE tablename = 'pdfs' ORDER BY cmd;
```

You should see policies that allow:
- `SELECT`: Public access (everyone can read)
- `INSERT`: Public access (everyone can upload)
- `UPDATE`: Admin only
- `DELETE`: Admin only

## Files Created
- `fix_pdf_insertion_permissions.sql` - Quick fix for the insertion issue
- `comprehensive_pdf_permissions.sql` - Complete permissions setup
- `PDF_UPLOAD_PERMISSION_FIX.md` - This documentation file

## Security Considerations
This solution maintains security by:
- Keeping admin-only restrictions for sensitive operations (update/delete)
- Allowing content contribution from all users (upload)
- Maintaining public read access for the library functionality

The approach encourages user participation while preserving administrative control over content management.
