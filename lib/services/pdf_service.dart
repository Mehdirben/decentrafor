import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/pdf_document.dart';

class PdfService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Get all PDFs from the database
  static Future<List<PdfDocument>> getAllPdfs() async {
    try {
      final response = await _client
          .from('pdfs')
          .select()
          .order('created_at', ascending: false);
      
      return response.map<PdfDocument>((json) => PdfDocument.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch PDFs: $e');
    }
  }

  // Get PDFs by category
  static Future<List<PdfDocument>> getPdfsByCategory(String category) async {
    try {
      final response = await _client
          .from('pdfs')
          .select()
          .eq('category', category)
          .order('created_at', ascending: false);
      
      return response.map<PdfDocument>((json) => PdfDocument.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch PDFs by category: $e');
    }
  }

  // Search PDFs by title or description
  static Future<List<PdfDocument>> searchPdfs(String query) async {
    try {
      final response = await _client
          .from('pdfs')
          .select()
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false);
      
      return response.map<PdfDocument>((json) => PdfDocument.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search PDFs: $e');
    }
  }

  // Upload PDF file to Supabase Storage
  static Future<String> uploadPdf(File file, String fileName) async {
    try {
      // Create a unique filename to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = fileName.split('.').last;
      final uniqueFileName = '${fileName.replaceAll('.pdf', '')}_$timestamp.$fileExtension';
      final filePath = 'pdfs/$uniqueFileName';
      
      // Upload the file to Supabase Storage
      await _client.storage
          .from(SupabaseConfig.pdfBucketName)
          .upload(filePath, file);
      
      // Get the public URL
      final String publicUrl = _client.storage
          .from(SupabaseConfig.pdfBucketName)
          .getPublicUrl(filePath);
      
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload PDF to Supabase Storage: $e');
    }
  }

  // Upload thumbnail to Supabase Storage
  static Future<String> uploadThumbnail(File file, String fileName) async {
    try {
      // Create a unique filename to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = file.path.split('.').last;
      final uniqueFileName = '${fileName.replaceAll('.${fileName.split('.').last}', '')}_thumbnail_$timestamp.$fileExtension';
      final filePath = 'thumbnails/$uniqueFileName';
      
      // Upload the file to Supabase Storage
      await _client.storage
          .from(SupabaseConfig.pdfBucketName)
          .upload(filePath, file);
      
      // Get the public URL
      final String publicUrl = _client.storage
          .from(SupabaseConfig.pdfBucketName)
          .getPublicUrl(filePath);
      
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload thumbnail to Supabase Storage: $e');
    }
  }

  // Add new PDF to database
  static Future<PdfDocument> addPdf({
    required String title,
    required String description,
    required String fileName,
    required String fileUrl,
    required int fileSize,
    required String category,
    required List<String> tags,
    String? thumbnailUrl,
  }) async {
    try {
      final response = await _client
          .from('pdfs')
          .insert({
            'title': title,
            'description': description,
            'file_name': fileName,
            'file_url': fileUrl,
            'file_size': fileSize,
            'category': category,
            'tags': tags,
            'thumbnail_url': thumbnailUrl,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      
      return PdfDocument.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add PDF: $e');
    }
  }

  // Delete PDF
  static Future<void> deletePdf(String id) async {
    try {
      // Check current user and admin status
      final currentUser = _client.auth.currentUser;
      print('Debug: Current user: ${currentUser?.email} (ID: ${currentUser?.id})');
      
      // First, get the PDF info to extract the file paths
      final response = await _client
          .from('pdfs')
          .select('file_url, thumbnail_url')
          .eq('id', id)
          .single();
      
      final String fileUrl = response['file_url'];
      final String? thumbnailUrl = response['thumbnail_url'];
      
      print('Debug: Starting deletion for PDF ID: $id');
      print('Debug: PDF fileUrl: $fileUrl');
      print('Debug: Thumbnail URL: $thumbnailUrl');
      
      // Delete the main PDF file from storage
      if (fileUrl.isNotEmpty) {
        try {
          // Extract the file path from the URL
          Uri uri = Uri.parse(fileUrl);
          String path = uri.path;
          print('Debug: Full URL path: "$path"');
          
          // Path should be like: /storage/v1/object/public/pdfs/pdfs/filename.pdf
          if (path.contains('/storage/v1/object/public/${SupabaseConfig.pdfBucketName}/')) {
            final filePath = path.split('/storage/v1/object/public/${SupabaseConfig.pdfBucketName}/').last;
            print('Debug: Extracted PDF file path: "$filePath"');
            
            await _client.storage
                .from(SupabaseConfig.pdfBucketName)
                .remove([filePath]);
            print('Debug: Successfully deleted PDF file from storage');
          } else {
            print('Debug: PDF URL path does not match expected format: $path');
          }
        } catch (e) {
          print('Debug: Failed to delete PDF file from storage: $e');
          // Continue with deletion process - don't fail completely
        }
      }
      
      // Delete the thumbnail file from storage
      if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
        try {
          Uri uri = Uri.parse(thumbnailUrl);
          String path = uri.path;
          print('Debug: Full thumbnail path: "$path"');
          
          if (path.contains('/storage/v1/object/public/${SupabaseConfig.pdfBucketName}/')) {
            final thumbnailPath = path.split('/storage/v1/object/public/${SupabaseConfig.pdfBucketName}/').last;
            print('Debug: Extracted thumbnail file path: "$thumbnailPath"');
            
            await _client.storage
                .from(SupabaseConfig.pdfBucketName)
                .remove([thumbnailPath]);
            print('Debug: Successfully deleted thumbnail file from storage');
          } else {
            print('Debug: Thumbnail URL path does not match expected format: $path');
          }
        } catch (e) {
          print('Debug: Failed to delete thumbnail file from storage: $e');
          // Continue with deletion process - don't fail completely
        }
      }
      
      // Delete the record from the database (this is the most important part)
      await _client
          .from('pdfs')
          .delete()
          .eq('id', id);
      print('Debug: Successfully deleted PDF record from database');
      
    } catch (e) {
      print('Debug: Critical error in deletePdf: $e');
      throw Exception('Failed to delete PDF: $e');
    }
  }

  // Update PDF
  static Future<PdfDocument> updatePdf(String id, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await _client
          .from('pdfs')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      
      return PdfDocument.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update PDF: $e');
    }
  }
}
