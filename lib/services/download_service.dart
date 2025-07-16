import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import '../models/pdf_document.dart';

class DownloadService {
  static final Dio _dio = Dio();
  static const String _downloadFolder = 'PDF_Store';

  // Get the downloads directory
  static Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // For Android, use the Downloads directory
      final directory = Directory('/storage/emulated/0/Download/$_downloadFolder');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
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
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (status.isDenied) {
        final result = await Permission.storage.request();
        return result.isGranted;
      }
      return status.isGranted;
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

      // Download the file
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

      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading PDF: $e');
      }
      throw Exception('Failed to download PDF: $e');
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
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
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
