import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pdf_provider.dart';
import '../models/pdf_document.dart';
import '../screens/pdf_viewer_screen.dart';
import '../screens/add_pdf_screen.dart';

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
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPdfScreen()),
              );
            },
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

class PdfCard extends StatelessWidget {
  final PdfDocument pdf;

  const PdfCard({super.key, required this.pdf});

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
              builder: (context) => PdfViewerScreen(pdf: pdf),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PDF icon
              const Center(
                child: Icon(
                  Icons.picture_as_pdf,
                  size: 48,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              
              // Title
              Text(
                pdf.title,
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
                pdf.description,
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
                      pdf.category,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  Text(
                    '${(pdf.fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
