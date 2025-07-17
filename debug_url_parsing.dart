// Debug script to understand URL structure
// This is for debugging purposes only

void debugUrlParsing() {
  // Example URLs
  const pdfUrl = 'https://dvkpfqpofjgruymzvyer.supabase.co/storage/v1/object/public/pdfs/pdfs/example_1234567890.pdf';
  const thumbnailUrl = 'https://dvkpfqpofjgruymzvyer.supabase.co/storage/v1/object/public/pdfs/thumbnails/example_thumbnail_1234567890.jpg';
  
  // Extract paths
  const bucketName = 'pdfs';
  
  if (pdfUrl.contains('supabase.co/storage/v1/object/public/$bucketName/')) {
    final pdfPath = pdfUrl.split('$bucketName/').last;
    print('PDF Path: $pdfPath'); // Should be: pdfs/example_1234567890.pdf
  }
  
  if (thumbnailUrl.contains('supabase.co/storage/v1/object/public/$bucketName/')) {
    final thumbnailPath = thumbnailUrl.split('$bucketName/').last;
    print('Thumbnail Path: $thumbnailPath'); // Should be: thumbnails/example_thumbnail_1234567890.jpg
  }
}
