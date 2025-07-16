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

  // Add new PDF to database
  static Future<PdfDocument> addPdf({
    required String title,
    required String description,
    required String fileName,
    required String fileUrl,
    required int fileSize,
    required String category,
    required List<String> tags,
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
      // First, get the PDF info to extract the file path
      final response = await _client
          .from('pdfs')
          .select('file_url')
          .eq('id', id)
          .single();
      
      final String fileUrl = response['file_url'];
      
      // Extract the file path from the URL
      // URL format: https://[project-id].supabase.co/storage/v1/object/public/pdfs/filename
      if (fileUrl.contains('supabase.co/storage/v1/object/public/${SupabaseConfig.pdfBucketName}/')) {
        final filePath = fileUrl.split('${SupabaseConfig.pdfBucketName}/').last;
        
        // Delete the file from storage
        await _client.storage
            .from(SupabaseConfig.pdfBucketName)
            .remove(['pdfs/$filePath']);
      }
      
      // Delete the record from the database
      await _client
          .from('pdfs')
          .delete()
          .eq('id', id);
    } catch (e) {
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
