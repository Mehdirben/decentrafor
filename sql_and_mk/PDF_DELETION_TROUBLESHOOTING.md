# PDF Deletion Troubleshooting

## Issue: Thumbnail deletes but PDF doesn't

### Debugging Steps

1. **Check Console Output**: The updated delete method now includes debug logging. Look for:
   ```
   Debug: Deleting PDF with fileUrl: [URL]
   Debug: Deleting thumbnail with thumbnailUrl: [URL]
   Debug: Extracted PDF file path: [PATH]
   Debug: Extracted thumbnail file path: [PATH]
   Debug: Deleting files: [LIST]
   Debug: Successfully deleted all files from storage
   Debug: Successfully deleted PDF record from database
   ```

2. **Common Issues**:
   - **URL Format Mismatch**: PDF URLs might have different format than expected
   - **Path Extraction Error**: The split operation might not work correctly
   - **Storage Permission**: Admin might not have permission to delete certain files
   - **File Not Found**: PDF file might already be missing from storage

### Expected File Paths

Based on upload logic:
- **PDF**: `pdfs/filename_timestamp.pdf`
- **Thumbnail**: `thumbnails/filename_thumbnail_timestamp.jpg`

### URL Format
```
https://[project-id].supabase.co/storage/v1/object/public/pdfs/[file-path]
```

### Quick Fix if Issue Persists

If the problem continues, we can fall back to the original approach with individual file deletion and proper error handling:

```dart
// Delete PDF file
try {
  await _client.storage.from(SupabaseConfig.pdfBucketName).remove([pdfPath]);
} catch (e) {
  print('PDF file deletion failed: $e');
  // Continue anyway
}

// Delete thumbnail file  
try {
  await _client.storage.from(SupabaseConfig.pdfBucketName).remove([thumbnailPath]);
} catch (e) {
  print('Thumbnail deletion failed: $e');
  // Continue anyway
}
```

### Next Steps

1. Try deleting a PDF and check the debug console
2. Report the exact debug output
3. We can adjust the path extraction logic based on the actual URLs
