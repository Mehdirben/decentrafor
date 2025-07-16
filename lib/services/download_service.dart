import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../models/pdf_document.dart';

class DownloadService {
  static final Dio _dio = Dio();
  static const String _downloadFolder = 'PDF_Store';

  // Get the downloads directory
  static Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Use app-specific external storage directory (doesn't require permissions)
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final downloadDir = Directory('${directory.path}/$_downloadFolder');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        return downloadDir;
      } else {
        // Fallback to app documents directory
        final directory = await getApplicationDocumentsDirectory();
        final downloadDir = Directory('${directory.path}/$_downloadFolder');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        return downloadDir;
      }
    } else {
      // For iOS and other platforms, use app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${directory.path}/$_downloadFolder');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      return downloadDir;
    }
  }

  // Check if storage permission is granted
  static Future<bool> _checkStoragePermission() async {
    // Since we're using app-specific storage, we don't need permissions
    // But we can still check if external storage is available
    if (Platform.isAndroid) {
      try {
        final directory = await getExternalStorageDirectory();
        return directory != null;
      } catch (e) {
        return false;
      }
    }
    return true; // iOS doesn't need storage permission for app documents
  }

  // Download a PDF file
  static Future<String?> downloadPdf(
    PdfDocument pdf, {
    Function(int received, int total)? onProgress,
  }) async {
    try {
      // Check and request storage permission
      if (!await _checkStoragePermission()) {
        throw Exception('Storage permission denied');
      }

      // Get download directory
      final downloadDir = await _getDownloadDirectory();
      
      // Create filename with timestamp to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${pdf.title.replaceAll(RegExp(r'[^\w\s-]'), '')}_$timestamp.pdf';
      final filePath = '${downloadDir.path}/$fileName';

      // Download the PDF file
      await _dio.download(
        pdf.fileUrl,
        filePath,
        onReceiveProgress: onProgress,
        options: Options(
          headers: {
            'User-Agent': 'Flutter PDF Store App',
          },
        ),
      );

      // Download the thumbnail if available
      if (pdf.thumbnailUrl != null && pdf.thumbnailUrl!.isNotEmpty) {
        await _downloadThumbnail(pdf, filePath);
      }

      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading PDF: $e');
      }
      throw Exception('Failed to download PDF: $e');
    }
  }

  // Download thumbnail for a PDF
  static Future<void> _downloadThumbnail(PdfDocument pdf, String pdfPath) async {
    try {
      final thumbnailPath = pdfPath.replaceAll('.pdf', '_thumbnail.jpg');
      
      await _dio.download(
        pdf.thumbnailUrl!,
        thumbnailPath,
        options: Options(
          headers: {
            'User-Agent': 'Flutter PDF Store App',
          },
        ),
      );
      
      if (kDebugMode) {
        print('Thumbnail downloaded successfully: $thumbnailPath');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading thumbnail: $e');
      }
      // Don't throw error for thumbnail download failure, just log it
    }
  }

  // Check if a PDF is already downloaded
  static Future<bool> isPdfDownloaded(PdfDocument pdf) async {
    try {
      final downloadDir = await _getDownloadDirectory();
      final files = await downloadDir.list().toList();
      
      // Check if any file contains the PDF title
      for (var file in files) {
        if (file is File && file.path.contains(pdf.title.replaceAll(RegExp(r'[^\w\s-]'), ''))) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get downloaded PDF file path
  static Future<String?> getDownloadedPdfPath(PdfDocument pdf) async {
    try {
      final downloadDir = await _getDownloadDirectory();
      final files = await downloadDir.list().toList();
      
      // Find the file that contains the PDF title
      for (var file in files) {
        if (file is File && file.path.contains(pdf.title.replaceAll(RegExp(r'[^\w\s-]'), ''))) {
          return file.path;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get all downloaded PDFs
  static Future<List<String>> getDownloadedPdfs() async {
    try {
      final downloadDir = await _getDownloadDirectory();
      final files = await downloadDir.list().toList();
      
      return files
          .where((file) => file is File && file.path.endsWith('.pdf'))
          .map((file) => file.path)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Delete a downloaded PDF
  static Future<bool> deleteDownloadedPdf(String filePath) async {
    try {
      final file = File(filePath);
      final thumbnailPath = filePath.replaceAll('.pdf', '_thumbnail.jpg');
      final thumbnailFile = File(thumbnailPath);
      
      bool pdfDeleted = false;
      
      // Delete PDF file
      if (await file.exists()) {
        await file.delete();
        pdfDeleted = true;
      }
      
      // Delete thumbnail file if it exists
      if (await thumbnailFile.exists()) {
        try {
          await thumbnailFile.delete();
        } catch (e) {
          if (kDebugMode) {
            print('Error deleting thumbnail: $e');
          }
          // Continue even if thumbnail deletion fails
        }
      }
      
      return pdfDeleted;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting downloaded PDF: $e');
      }
      return false;
    }
  }

  // Get download directory path for user reference
  static Future<String> getDownloadDirectoryPath() async {
    final directory = await _getDownloadDirectory();
    return directory.path;
  }

  // Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
