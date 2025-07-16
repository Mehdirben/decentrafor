import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';
import '../models/pdf_document.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({Key? key}) : super(key: key);

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _storageInfo = {};
  List<Map<String, dynamic>> _uploadResults = [];
  List<PdfDocument> _allPdfs = [];
  bool _showPdfList = false;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
    _loadAllPdfs();
  }

  Future<void> _loadAllPdfs() async {
    try {
      final pdfs = await PdfService.getAllPdfs();
      setState(() {
        _allPdfs = pdfs;
      });
    } catch (e) {
      _showError('Failed to load PDFs: $e');
    }
  }

  Future<void> _loadStorageInfo() async {
    try {
      final info = await StorageService.getStorageInfo();
      setState(() {
        _storageInfo = info;
      });
    } catch (e) {
      _showError('Failed to load storage info: $e');
    }
  }

  Future<void> _uploadSamplePdfs() async {
    setState(() {
      _isLoading = true;
      _uploadResults = [];
    });

    try {
      final results = await StorageService.uploadSamplePdfs();
      setState(() {
        _uploadResults = results;
      });
      
      await _loadStorageInfo();
      
      final successCount = results.where((r) => r['status'] == 'success').length;
      final failedCount = results.where((r) => r['status'] == 'failed').length;
      
      _showSuccess('Upload completed: $successCount successful, $failedCount failed');
    } catch (e) {
      _showError('Failed to upload sample PDFs: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testDatabaseConnection() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await StorageService.testDatabaseConnection();
      _showSuccess('Database connection test passed!');
    } catch (e) {
      _showError('Database connection test failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testStorageBucket() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await StorageService.testStorageBucket();
      _showSuccess('Storage bucket test passed!');
    } catch (e) {
      _showError('Storage bucket test failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePdf(String pdfId, String title) async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete PDF'),
        content: Text('Are you sure you want to delete "$title"?\n\nThis will remove the PDF from both the database and storage.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await PdfService.deletePdf(pdfId);
        _showSuccess('PDF "$title" deleted successfully');
        await _loadAllPdfs();
        await _loadStorageInfo();
      } catch (e) {
        _showError('Failed to delete PDF: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _togglePdfList() async {
    setState(() {
      _showPdfList = !_showPdfList;
    });
    if (_showPdfList) {
      await _loadAllPdfs();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Storage Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Storage Information',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.folder, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text('Files: ${_storageInfo['fileCount'] ?? 0}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.storage, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text('Total Size: ${_storageInfo['totalSizeFormatted'] ?? '0 B'}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Actions
            Text(
              'Actions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            // Upload Sample PDFs Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _uploadSamplePdfs,
                icon: const Icon(Icons.upload),
                label: const Text('Upload Sample PDFs'),
              ),
            ),
            const SizedBox(height: 8),
            
            // Manage PDFs Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _togglePdfList,
                icon: Icon(_showPdfList ? Icons.visibility_off : Icons.visibility),
                label: Text(_showPdfList ? 'Hide PDFs' : 'Manage PDFs'),
              ),
            ),
            const SizedBox(height: 8),
            
            // Test Database Connection Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testDatabaseConnection,
                icon: const Icon(Icons.bug_report),
                label: const Text('Test Database Connection'),
              ),
            ),
            const SizedBox(height: 8),
            
            // Test Storage Bucket Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testStorageBucket,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Test Storage Bucket'),
              ),
            ),
            const SizedBox(height: 8),
            
            // Toggle PDF List Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _togglePdfList,
                icon: const Icon(Icons.list),
                label: Text(_showPdfList ? 'Hide PDF List' : 'Show PDF List'),
              ),
            ),
            const SizedBox(height: 16),
            
            // Loading indicator
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            
            // Upload Results
            if (_uploadResults.isNotEmpty) ...[
              Text(
                'Upload Results',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _uploadResults.length,
                  itemBuilder: (context, index) {
                    final result = _uploadResults[index];
                    final isSuccess = result['status'] == 'success';
                    
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          isSuccess ? Icons.check_circle : Icons.error,
                          color: isSuccess ? Colors.green : Colors.red,
                        ),
                        title: Text(result['title']),
                        subtitle: isSuccess 
                            ? const Text('Uploaded successfully')
                            : Text('Failed: ${result['error']}'),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            // PDF Management Section
            if (_showPdfList) ...[
              const SizedBox(height: 16),
              Text(
                'PDF Management (${_allPdfs.length} PDFs)',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _allPdfs.length,
                  itemBuilder: (context, index) {
                    final pdf = _allPdfs[index];
                    
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.picture_as_pdf,
                          color: Theme.of(context).primaryColor,
                        ),
                        title: Text(pdf.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Size: ${pdf.sizeFormatted}'),
                            Text('Category: ${pdf.category}'),
                            Text('Created: ${pdf.createdAt.toString().split(' ')[0]}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: _isLoading ? null : () => _deletePdf(pdf.id, pdf.title),
                          tooltip: 'Delete PDF',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else if (!_uploadResults.isNotEmpty) ...[
              const Expanded(child: SizedBox()), // Spacer when no content
            ],
          ],
        ),
      ),
    );
  }
}
