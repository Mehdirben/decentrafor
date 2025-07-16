import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../config/supabase_config.dart';
import '../services/pdf_service.dart';

class StorageService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Create the PDFs bucket if it doesn't exist
  static Future<void> createPdfBucket() async {
    try {
      await _client.storage.createBucket(
        SupabaseConfig.pdfBucketName,
        BucketOptions(
          public: true,
          fileSizeLimit: '50MB',
          allowedMimeTypes: ['application/pdf'],
        ),
      );
    } catch (e) {
      // Bucket might already exist, that's okay
      print('Bucket creation result: $e');
    }
  }

  // Upload a sample PDF from URL to Supabase Storage
  static Future<String> uploadSamplePdfFromUrl(String url, String fileName) async {
    try {
      // Download the PDF from the URL
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to download PDF from URL');
      }

      // Create a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(response.bodyBytes);

      // Upload to Supabase Storage
      final publicUrl = await PdfService.uploadPdf(tempFile, fileName);

      // Clean up temporary file
      await tempFile.delete();

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload sample PDF: $e');
    }
  }

  // Get all files in the PDFs bucket
  static Future<List<FileObject>> listPdfFiles() async {
    try {
      final files = await _client.storage
          .from(SupabaseConfig.pdfBucketName)
          .list(path: 'pdfs');
      return files;
    } catch (e) {
      throw Exception('Failed to list PDF files: $e');
    }
  }

  // Get storage usage information
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final files = await listPdfFiles();
      int totalSize = 0;
      int fileCount = files.length;

      for (var file in files) {
        final size = file.metadata?['size'];
        if (size != null) {
          totalSize += (size as num).toInt();
        }
      }

      return {
        'fileCount': fileCount,
        'totalSize': totalSize,
        'totalSizeFormatted': _formatFileSize(totalSize),
      };
    } catch (e) {
      return {
        'fileCount': 0,
        'totalSize': 0,
        'totalSizeFormatted': '0 B',
      };
    }
  }

  // Delete a file from storage
  static Future<void> deleteFile(String filePath) async {
    try {
      await _client.storage
          .from(SupabaseConfig.pdfBucketName)
          .remove([filePath]);
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // Format file size for display
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Upload sample PDFs to Supabase Storage
  static Future<List<Map<String, dynamic>>> uploadSamplePdfs() async {
    final samplePdfs = [
      {
        'title': 'Flutter Development Guide',
        'description': 'A comprehensive guide to Flutter development covering widgets, state management, and best practices.',
        'fileName': 'flutter_guide.pdf',
        'url': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
        'category': 'Technology',
        'tags': ['flutter', 'development', 'guide'],
        'estimatedSize': 2450000,
      },
      {
        'title': 'Business Strategy 2024',
        'description': 'Annual business strategy document outlining goals, objectives, and key performance indicators.',
        'fileName': 'business_strategy_2024.pdf',
        'url': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
        'category': 'Business',
        'tags': ['strategy', 'business', '2024'],
        'estimatedSize': 1890000,
      },
      {
        'title': 'Introduction to Machine Learning',
        'description': 'Educational material covering the basics of machine learning algorithms and applications.',
        'fileName': 'ml_intro.pdf',
        'url': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
        'category': 'Education',
        'tags': ['machine learning', 'education', 'ai'],
        'estimatedSize': 3200000,
      },
      {
        'title': 'Health and Wellness Report',
        'description': 'Annual health and wellness report with statistics and recommendations for healthy living.',
        'fileName': 'health_wellness_2024.pdf',
        'url': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
        'category': 'Health',
        'tags': ['health', 'wellness', 'report'],
        'estimatedSize': 1560000,
      },
      {
        'title': 'Science Research Paper',
        'description': 'Research paper on renewable energy sources and their impact on climate change.',
        'fileName': 'renewable_energy_research.pdf',
        'url': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
        'category': 'Science',
        'tags': ['research', 'renewable energy', 'climate'],
        'estimatedSize': 4100000,
      }
    ];

    List<Map<String, dynamic>> uploadedPdfs = [];

    for (var pdf in samplePdfs) {
      try {
        // Upload PDF to Supabase Storage
        final fileUrl = await uploadSamplePdfFromUrl(
          pdf['url'] as String, 
          pdf['fileName'] as String
        );
        
        // Add to database
        await PdfService.addPdf(
          title: pdf['title'] as String,
          description: pdf['description'] as String,
          fileName: pdf['fileName'] as String,
          fileUrl: fileUrl,
          fileSize: pdf['estimatedSize'] as int,
          category: pdf['category'] as String,
          tags: List<String>.from(pdf['tags'] as List),
        );
        
        uploadedPdfs.add({
          'title': pdf['title'],
          'fileUrl': fileUrl,
          'status': 'success',
        });
      } catch (e) {
        uploadedPdfs.add({
          'title': pdf['title'],
          'status': 'failed',
          'error': e.toString(),
        });
      }
    }

    return uploadedPdfs;
  }

  // Test database connection and RLS policies
  static Future<void> testDatabaseConnection() async {
    try {
      // Test basic select
      final selectResult = await _client.from('pdfs').select().limit(1);
      print('Select test passed: ${selectResult.length} records');
      
      // Test insert with minimal data
      final testData = {
        'title': 'Test PDF',
        'description': 'This is a test PDF',
        'file_name': 'test.pdf',
        'file_url': 'https://example.com/test.pdf',
        'file_size': 1024,
        'category': 'Test',
        'tags': ['test'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final insertResult = await _client.from('pdfs').insert(testData).select();
      print('Insert test passed: ${insertResult.length} records inserted');
      
      // Clean up test data
      if (insertResult.isNotEmpty) {
        await _client.from('pdfs').delete().eq('id', insertResult.first['id']);
        print('Test data cleaned up');
      }
    } catch (e) {
      print('Database test failed: $e');
      rethrow;
    }
  }

  // Test storage bucket access
  static Future<void> testStorageBucket() async {
    try {
      // Test if we can list files in the bucket
      final files = await _client.storage
          .from(SupabaseConfig.pdfBucketName)
          .list(path: 'pdfs');
      print('Storage bucket test passed: ${files.length} files found');
      
      // Test if we can get bucket info
      final buckets = await _client.storage.listBuckets();
      final pdfBucket = buckets.where((b) => b.id == SupabaseConfig.pdfBucketName).toList();
      print('PDF bucket exists: ${pdfBucket.isNotEmpty}');
      
    } catch (e) {
      print('Storage bucket test failed: $e');
      rethrow;
    }
  }
}
