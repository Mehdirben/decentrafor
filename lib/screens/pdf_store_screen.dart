import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pdf_provider.dart';
import '../models/pdf_document.dart';
import '../screens/pdf_viewer_screen.dart';
import '../screens/add_pdf_screen.dart';
import '../screens/downloads_screen.dart';
import '../screens/storage_screen.dart';
import '../services/download_service.dart';

class PdfStoreScreen extends StatefulWidget {
  const PdfStoreScreen({super.key});

  @override
  State<PdfStoreScreen> createState() => _PdfStoreScreenState();
}

class _PdfStoreScreenState extends State<PdfStoreScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PdfProvider>(context, listen: false).loadPdfs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Store'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StorageScreen()),
              );
            },
            tooltip: 'Storage Management',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DownloadsScreen()),
              );
            },
            tooltip: 'Downloads',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPdfScreen()),
              );
            },
            tooltip: 'Add PDF',
          ),
        ],
      ),
      body: Consumer<PdfProvider>(
        builder: (context, pdfProvider, child) {
          if (pdfProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (pdfProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${pdfProvider.error}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      pdfProvider.clearError();
                      pdfProvider.loadPdfs();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search PDFs...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              pdfProvider.searchPdfs('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    pdfProvider.searchPdfs(value);
                  },
                ),
              ),
              
              // Category filter
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: pdfProvider.categories.length,
                  itemBuilder: (context, index) {
                    final category = pdfProvider.categories[index];
                    final isSelected = pdfProvider.selectedCategory == category;
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          pdfProvider.filterByCategory(category);
                        },
                        selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // PDF grid
              Expanded(
                child: pdfProvider.pdfs.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No PDFs found',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: pdfProvider.pdfs.length,
                        itemBuilder: (context, index) {
                          final pdf = pdfProvider.pdfs[index];
                          return PdfCard(pdf: pdf);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PdfCard extends StatefulWidget {
  final PdfDocument pdf;

  const PdfCard({super.key, required this.pdf});

  @override
  State<PdfCard> createState() => _PdfCardState();
}

class _PdfCardState extends State<PdfCard> {
  bool _isDownloading = false;
  bool _isDownloaded = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();
  }

  Future<void> _checkDownloadStatus() async {
    final isDownloaded = await DownloadService.isPdfDownloaded(widget.pdf);
    if (mounted) {
      setState(() {
        _isDownloaded = isDownloaded;
      });
    }
  }

  Future<void> _downloadPdf() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final filePath = await DownloadService.downloadPdf(
        widget.pdf,
        onProgress: (received, total) {
          if (mounted) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isDownloaded = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF downloaded successfully'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfViewerScreen(
                      pdf: widget.pdf,
                      localPath: filePath,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openDownloadedPdf() async {
    final filePath = await DownloadService.getDownloadedPdfPath(widget.pdf);
    if (filePath != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(
            pdf: widget.pdf,
            localPath: filePath,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PdfViewerScreen(pdf: widget.pdf),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PDF icon and download button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    size: 48,
                    color: Colors.red,
                  ),
                  _buildDownloadButton(),
                ],
              ),
              const SizedBox(height: 12),
              
              // Download progress bar
              if (_isDownloading)
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: _downloadProgress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(_downloadProgress * 100).toInt()}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              
              // Title
              Text(
                widget.pdf.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Description
              Text(
                widget.pdf.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              
              // Category and size
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.pdf.category,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (_isDownloaded)
                        const Icon(
                          Icons.download_done,
                          size: 16,
                          color: Colors.green,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        '${(widget.pdf.fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadButton() {
    if (_isDownloading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_isDownloaded) {
      return IconButton(
        icon: const Icon(
          Icons.download_done,
          color: Colors.green,
          size: 20,
        ),
        onPressed: _openDownloadedPdf,
        tooltip: 'Open downloaded PDF',
      );
    }

    return IconButton(
      icon: const Icon(
        Icons.download,
        color: Colors.blue,
        size: 20,
      ),
      onPressed: _downloadPdf,
      tooltip: 'Download PDF',
    );
  }
}
