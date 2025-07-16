import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
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

class _PdfStoreScreenState extends State<PdfStoreScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _searchAnimationController;
  late Animation<double> _searchAnimation;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  bool _isSearchFocused = false;
  bool _isFabExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeOut,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PdfProvider>(context, listen: false).loadPdfs();
    });
  }

  @override
  void dispose() {
    _searchAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Consumer<PdfProvider>(
        builder: (context, pdfProvider, child) {
          if (pdfProvider.isLoading) {
            return _buildLoadingState();
          }

          if (pdfProvider.error != null) {
            return _buildErrorState(pdfProvider);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await Provider.of<PdfProvider>(context, listen: false).loadPdfs();
            },
            color: const Color(0xFF667EEA),
            backgroundColor: Colors.white,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    height:
                        MediaQuery.of(context).size.height *
                        0.28, // Responsive height
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Background pattern
                        Positioned.fill(
                          child: CustomPaint(
                            painter: GeometricPatternPainter(),
                          ),
                        ),
                        // Content
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              24,
                              20,
                              24,
                              10,
                            ), // Reduced top padding
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'PDF Library',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Discover and organize your documents',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, 20), // Overlap with header
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildSearchBar(),
                          const SizedBox(height: 20),
                          _buildCategoryFilter(pdfProvider),
                          const SizedBox(height: 24),
                          _buildStatsRow(pdfProvider),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    30,
                    20,
                    100,
                  ), // Added top padding to push PDFs down
                  sliver: pdfProvider.pdfs.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmptyState())
                      : SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final pdf = pdfProvider.pdfs[index];
                            return AnimatedContainer(
                              duration: Duration(
                                milliseconds: 300 + (index * 100),
                              ),
                              curve: Curves.easeOutBack,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ModernPdfListCard(pdf: pdf),
                            );
                          }, childCount: pdfProvider.pdfs.length),
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _buildExpandableFAB(),
    );
  }

  Widget _buildExpandableFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Expanded action buttons
        AnimatedBuilder(
          animation: _fabAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _fabAnimation.value,
              child: Opacity(
                opacity: _fabAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Storage button
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: FloatingActionButton(
                        heroTag: "storage",
                        onPressed: () {
                          _toggleFAB();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StorageScreen(),
                            ),
                          );
                        },
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        elevation: 6,
                        child: const Icon(Icons.storage_rounded),
                      ),
                    ),
                    // Downloads button
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: FloatingActionButton(
                        heroTag: "downloads",
                        onPressed: () {
                          _toggleFAB();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DownloadsScreen(),
                            ),
                          );
                        },
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 6,
                        child: const Icon(Icons.download_rounded),
                      ),
                    ),
                    // Add PDF button
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: FloatingActionButton(
                        heroTag: "add_pdf",
                        onPressed: () {
                          _toggleFAB();
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const AddPdfScreen(),
                              transitionsBuilder:
                                  (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                    child,
                                  ) {
                                    return SlideTransition(
                                      position: animation.drive(
                                        Tween(
                                          begin: const Offset(0.0, 1.0),
                                          end: Offset.zero,
                                        ).chain(
                                          CurveTween(curve: Curves.easeOut),
                                        ),
                                      ),
                                      child: child,
                                    );
                                  },
                              transitionDuration: const Duration(
                                milliseconds: 300,
                              ),
                            ),
                          );
                        },
                        backgroundColor: const Color(0xFF667EEA),
                        foregroundColor: Colors.white,
                        elevation: 6,
                        child: const Icon(Icons.add_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        // Main FAB
        FloatingActionButton(
          heroTag: "main",
          onPressed: _toggleFAB,
          backgroundColor: const Color(0xFF667EEA),
          foregroundColor: Colors.white,
          elevation: 8,
          child: AnimatedRotation(
            turns: _isFabExpanded
                ? 0.125
                : 0.0, // 45 degree rotation when expanded
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _isFabExpanded ? Icons.close_rounded : Icons.menu_rounded,
            ),
          ),
        ),
      ],
    );
  }

  void _toggleFAB() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
    });

    if (_isFabExpanded) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF667EEA), Color(0xFFF8FAFC)],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Loading your library...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(PdfProvider pdfProvider) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              pdfProvider.error!,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                pdfProvider.clearError();
                pdfProvider.loadPdfs();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedBuilder(
      animation: _searchAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: _isSearchFocused ? Colors.white : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isSearchFocused
                ? const Color(0xFF667EEA)
                : Colors.grey.withValues(alpha: 0.1),
          ),
          boxShadow: _isSearchFocused
              ? [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: TextField(
          controller: _searchController,
          onTap: () {
            setState(() {
              _isSearchFocused = true;
            });
            _searchAnimationController.forward();
          },
          onEditingComplete: () {
            setState(() {
              _isSearchFocused = false;
            });
            _searchAnimationController.reverse();
          },
          decoration: InputDecoration(
            hintText: 'Search your library...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: _isSearchFocused
                  ? const Color(0xFF667EEA)
                  : Colors.grey[600],
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, color: Colors.grey[600]),
                    onPressed: () {
                      _searchController.clear();
                      Provider.of<PdfProvider>(
                        context,
                        listen: false,
                      ).searchPdfs('');
                      setState(() {
                        _isSearchFocused = false;
                      });
                      _searchAnimationController.reverse();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (value) {
            Provider.of<PdfProvider>(context, listen: false).searchPdfs(value);
          },
        ),
      ),
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_searchAnimation.value * 0.02),
          child: child,
        );
      },
    );
  }

  Widget _buildCategoryFilter(PdfProvider pdfProvider) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: pdfProvider.categories.length,
        itemBuilder: (context, index) {
          final category = pdfProvider.categories[index];
          final isSelected = pdfProvider.selectedCategory == category;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      )
                    : null,
                color: isSelected ? null : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => pdfProvider.filterByCategory(category),
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(PdfProvider pdfProvider) {
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.library_books_rounded,
          label: 'Total PDFs',
          value: pdfProvider.pdfs.length.toString(),
          color: const Color(0xFF667EEA),
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.download_done_rounded,
          label: 'Downloaded',
          value: '${pdfProvider.pdfs.length}', // Remove filter for now
          color: const Color(0xFF10B981),
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.category_rounded,
          label: 'Categories',
          value: pdfProvider.categories.length.toString(),
          color: const Color(0xFF8B5CF6),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.folder_open_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your library is empty',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add your first PDF to get started',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPdfScreen()),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Modern PDF List Card optimized for list layout
class ModernPdfListCard extends StatefulWidget {
  final PdfDocument pdf;

  const ModernPdfListCard({super.key, required this.pdf});

  @override
  State<ModernPdfListCard> createState() => _ModernPdfListCardState();
}

class _ModernPdfListCardState extends State<ModernPdfListCard>
    with TickerProviderStateMixin {
  bool _isDownloading = false;
  bool _isDownloaded = false;
  double _downloadProgress = 0.0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _checkDownloadStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
            content: const Text('PDF downloaded successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PdfViewerScreen(pdf: widget.pdf, localPath: filePath),
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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
          builder: (context) =>
              PdfViewerScreen(pdf: widget.pdf, localPath: filePath),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                PdfViewerScreen(pdf: widget.pdf),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: animation.drive(
                        Tween(
                          begin: const Offset(0.0, 0.1),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeOut)),
                      ),
                      child: child,
                    ),
                  );
                },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    // Left side - PDF icon and category color
                    Container(
                      width: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getCategoryColor(
                              widget.pdf.category,
                            ).withValues(alpha: 0.1),
                            _getCategoryColor(
                              widget.pdf.category,
                            ).withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(
                              widget.pdf.category,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 32,
                            color: _getCategoryColor(widget.pdf.category),
                          ),
                        ),
                      ),
                    ),

                    // Middle - Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              widget.pdf.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 4),

                            // Description
                            Text(
                              widget.pdf.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const Spacer(),

                            // Download progress
                            if (_isDownloading)
                              Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: _downloadProgress,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _getCategoryColor(widget.pdf.category),
                                      ),
                                      minHeight: 4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(_downloadProgress * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),

                            // Bottom row - Category and size
                            if (!_isDownloading)
                              Row(
                                children: [
                                  // Category badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(
                                        widget.pdf.category,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _getCategoryColor(
                                          widget.pdf.category,
                                        ).withValues(alpha: 0.3),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      widget.pdf.category,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _getCategoryColor(
                                          widget.pdf.category,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),

                                  const Spacer(),

                                  // Size and download status
                                  Row(
                                    children: [
                                      if (_isDownloaded)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            right: 6,
                                          ),
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.download_done_rounded,
                                            size: 12,
                                            color: Colors.green,
                                          ),
                                        ),
                                      Text(
                                        '${(widget.pdf.fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
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

                    // Right side - Download button
                    Container(
                      width: 60,
                      child: Center(child: _buildListDownloadButton()),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListDownloadButton() {
    if (_isDownloading) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _getCategoryColor(widget.pdf.category).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _getCategoryColor(widget.pdf.category).withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: IconButton(
        icon: Icon(
          _isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
          color: _isDownloaded
              ? Colors.green
              : _getCategoryColor(widget.pdf.category),
          size: 18,
        ),
        onPressed: _isDownloaded ? _openDownloadedPdf : _downloadPdf,
        tooltip: _isDownloaded ? 'Open downloaded PDF' : 'Download PDF',
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'education':
        return const Color(0xFF3B82F6);
      case 'business':
        return const Color(0xFF10B981);
      case 'technology':
        return const Color(0xFF8B5CF6);
      case 'science':
        return const Color(0xFF06B6D4);
      case 'literature':
        return const Color(0xFFEF4444);
      case 'health':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF667EEA);
    }
  }
}

// Custom painter for geometric background pattern
class GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Draw geometric circles
    for (int i = 0; i < 5; i++) {
      final radius = (i + 1) * 20.0;
      final center = Offset(size.width * 0.8, size.height * 0.3);
      canvas.drawCircle(center, radius, paint);
    }

    // Draw geometric lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 10; i++) {
      final y = i * 20.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 50), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ModernPdfCard extends StatefulWidget {
  final PdfDocument pdf;

  const ModernPdfCard({super.key, required this.pdf});

  @override
  State<ModernPdfCard> createState() => _ModernPdfCardState();
}

class _ModernPdfCardState extends State<ModernPdfCard>
    with TickerProviderStateMixin {
  bool _isDownloading = false;
  bool _isDownloaded = false;
  double _downloadProgress = 0.0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _checkDownloadStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
            content: const Text('PDF downloaded successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PdfViewerScreen(pdf: widget.pdf, localPath: filePath),
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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
          builder: (context) =>
              PdfViewerScreen(pdf: widget.pdf, localPath: filePath),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                PdfViewerScreen(pdf: widget.pdf),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: animation.drive(
                        Tween(
                          begin: const Offset(0.0, 0.1),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeOut)),
                      ),
                      child: child,
                    ),
                  );
                },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Background gradient
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getCategoryColor(
                              widget.pdf.category,
                            ).withValues(alpha: 0.1),
                            _getCategoryColor(
                              widget.pdf.category,
                            ).withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with icon and download button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(
                                    widget.pdf.category,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.picture_as_pdf_rounded,
                                  size: 32,
                                  color: _getCategoryColor(widget.pdf.category),
                                ),
                              ),
                              _buildModernDownloadButton(),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Download progress
                          if (_isDownloading)
                            Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: _downloadProgress,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _getCategoryColor(widget.pdf.category),
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${(_downloadProgress * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),

                          // Title
                          Text(
                            widget.pdf.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 8),

                          // Description
                          Text(
                            widget.pdf.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const Spacer(),

                          // Footer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Category badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(
                                    widget.pdf.category,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getCategoryColor(
                                      widget.pdf.category,
                                    ).withValues(alpha: 0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  widget.pdf.category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _getCategoryColor(
                                      widget.pdf.category,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              // Size and download status
                              Row(
                                children: [
                                  if (_isDownloaded)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.download_done_rounded,
                                        size: 14,
                                        color: Colors.green,
                                      ),
                                    ),
                                  Text(
                                    '${(widget.pdf.fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernDownloadButton() {
    if (_isDownloading) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          _isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
          color: _isDownloaded
              ? Colors.green
              : _getCategoryColor(widget.pdf.category),
          size: 20,
        ),
        onPressed: _isDownloaded ? _openDownloadedPdf : _downloadPdf,
        tooltip: _isDownloaded ? 'Open downloaded PDF' : 'Download PDF',
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'education':
        return const Color(0xFF3B82F6);
      case 'business':
        return const Color(0xFF10B981);
      case 'technology':
        return const Color(0xFF8B5CF6);
      case 'science':
        return const Color(0xFF06B6D4);
      case 'literature':
        return const Color(0xFFEF4444);
      case 'health':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF667EEA);
    }
  }
}

// Legacy PdfCard class for backward compatibility
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
                    builder: (context) =>
                        PdfViewerScreen(pdf: widget.pdf, localPath: filePath),
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
          builder: (context) =>
              PdfViewerScreen(pdf: widget.pdf, localPath: filePath),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  const Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
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
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),

              // Category and size
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
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
        icon: const Icon(Icons.download_done, color: Colors.green, size: 20),
        onPressed: _openDownloadedPdf,
        tooltip: 'Open downloaded PDF',
      );
    }

    return IconButton(
      icon: const Icon(Icons.download, color: Colors.blue, size: 20),
      onPressed: _downloadPdf,
      tooltip: 'Download PDF',
    );
  }
}
