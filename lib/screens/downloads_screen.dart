import 'package:flutter/material.dart';
import 'dart:io';
import '../services/download_service.dart';
import '../models/pdf_document.dart';
import '../screens/pdf_viewer_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<String> _downloadedPdfs = [];
  bool _isLoading = true;
  String? _downloadPath;

  @override
  void initState() {
    super.initState();
    _loadDownloadedPdfs();
  }

  Future<void> _loadDownloadedPdfs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final downloadedPdfs = await DownloadService.getDownloadedPdfs();
      final downloadPath = await DownloadService.getDownloadDirectoryPath();
      
      if (mounted) {
        setState(() {
          _downloadedPdfs = downloadedPdfs;
          _downloadPath = downloadPath;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading downloads: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteDownloadedPdf(String filePath) async {
    final success = await DownloadService.deleteDownloadedPdf(filePath);
    
    if (success && mounted) {
      setState(() {
        _downloadedPdfs.remove(filePath);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete PDF'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getFileNameFromPath(String path) {
    return path.split('/').last;
  }

  Future<int> _getFileSize(String path) async {
    try {
      final file = File(path);
      return await file.length();
    } catch (e) {
      return 0;
    }
  }

  Future<void> _openPdf(String filePath) async {
    final fileName = _getFileNameFromPath(filePath);
    final fileSize = await _getFileSize(filePath);
    
    // Create a temporary PDF document for viewing
    final tempPdf = PdfDocument(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      title: fileName.replaceAll('.pdf', ''),
      description: 'Downloaded PDF file',
      fileName: fileName,
      fileUrl: '',
      fileSize: fileSize,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      category: 'Downloaded',
      tags: ['downloaded', 'offline'],
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(
            pdf: tempPdf,
            localPath: filePath,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDownloadedPdfs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Download info
                if (_downloadPath != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Download Location:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _downloadPath!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_downloadedPdfs.length} downloaded PDF(s)',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Downloaded PDFs list
                Expanded(
                  child: _downloadedPdfs.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.download_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No downloaded PDFs',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Download PDFs from the store to view them offline',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _downloadedPdfs.length,
                          itemBuilder: (context, index) {
                            final filePath = _downloadedPdfs[index];
                            return DownloadedPdfCard(
                              filePath: filePath,
                              onOpen: () => _openPdf(filePath),
                              onDelete: () => _deleteDownloadedPdf(filePath),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class DownloadedPdfCard extends StatefulWidget {
  final String filePath;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const DownloadedPdfCard({
    super.key,
    required this.filePath,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  State<DownloadedPdfCard> createState() => _DownloadedPdfCardState();
}

class _DownloadedPdfCardState extends State<DownloadedPdfCard> {
  int _fileSize = 0;
  DateTime? _lastModified;

  @override
  void initState() {
    super.initState();
    _getFileInfo();
  }

  Future<void> _getFileInfo() async {
    try {
      final file = File(widget.filePath);
      final stat = await file.stat();
      
      if (mounted) {
        setState(() {
          _fileSize = stat.size;
          _lastModified = stat.modified;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  String _getFileName() {
    return widget.filePath.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(
          Icons.picture_as_pdf,
          color: Colors.red,
          size: 40,
        ),
        title: Text(
          _getFileName(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_fileSize > 0)
              Text(
                'Size: ${DownloadService.formatFileSize(_fileSize)}',
                style: const TextStyle(fontSize: 12),
              ),
            if (_lastModified != null)
              Text(
                'Downloaded: ${_lastModified!.day}/${_lastModified!.month}/${_lastModified!.year}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'open',
              child: ListTile(
                leading: Icon(Icons.open_in_new),
                title: Text('Open'),
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete'),
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'open') {
              widget.onOpen();
            } else if (value == 'delete') {
              _showDeleteConfirmation();
            }
          },
        ),
        onTap: widget.onOpen,
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete PDF'),
        content: Text('Are you sure you want to delete "${_getFileName()}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
