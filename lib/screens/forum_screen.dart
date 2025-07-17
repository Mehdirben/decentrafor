import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/forum_provider.dart';
import '../providers/username_provider.dart';
import '../models/forum_category.dart';
import '../services/admin_features_service.dart';
import 'forum_category_screen.dart';
import 'forum_search_screen.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final _scrollController = ScrollController();
  bool _isScrolled = false;
  
  Future<bool> _isAdminWithFeatures() async {
    final adminFeaturesEnabled = await AdminFeaturesService.isEnabled();
    final usernameProvider = Provider.of<UsernameProvider>(context, listen: false);
    return usernameProvider.isAdmin && adminFeaturesEnabled;
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ForumProvider>().loadCategories();
    });
  }

  void _onScroll() {
    // Trigger color change when scrolled more than 20 pixels
    final isScrolled = _scrollController.offset > 20;
    if (isScrolled != _isScrolled) {
      setState(() {
        _isScrolled = isScrolled;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: _isScrolled ? const Color(0xFF1F2937) : Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                collapseMode: CollapseMode.pin,
                title: Text(
                  'Education Forum',
                  style: TextStyle(
                    color: _isScrolled ? const Color(0xFF1F2937) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                background: Container(
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
                      // Safe area for content
                      const SafeArea(child: SizedBox.expand()),
                    ],
                  ),
                ),
              ),
              actions: [
                // Username display
                Consumer<UsernameProvider>(
                  builder: (context, usernameProvider, child) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isScrolled 
                            ? const Color(0xFF667EEA).withOpacity(0.1)
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isScrolled 
                              ? const Color(0xFF667EEA).withOpacity(0.3)
                              : Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 16,
                            color: _isScrolled 
                                ? const Color(0xFF667EEA)
                                : Colors.white,
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 80),
                            child: Text(
                              usernameProvider.currentUsername ?? 'User',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: _isScrolled 
                                    ? const Color(0xFF667EEA)
                                    : Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Search icon
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isScrolled 
                            ? const Color(0xFF667EEA).withOpacity(0.1)
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isScrolled 
                              ? const Color(0xFF667EEA).withOpacity(0.3)
                              : Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.search_rounded,
                        color: _isScrolled 
                            ? const Color(0xFF667EEA)
                            : Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ForumSearchScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ];
        },
        body: Consumer<ForumProvider>(
          builder: (context, forumProvider, child) {
            if (forumProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (forumProvider.error != null) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Something went wrong',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        forumProvider.error!,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () => forumProvider.loadCategories(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Try Again',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (forumProvider.categories.isEmpty) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'No Categories Yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Forum categories will appear here when they\'re created. Check back later for discussions!',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => forumProvider.loadCategories(),
              color: const Color(0xFF667EEA),
              backgroundColor: Colors.white,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSectionHeader(),
                  const SizedBox(height: 20),
                  ...forumProvider.categories.map((category) => 
                    _buildCategoryCard(context, category)
                  ),
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FutureBuilder<bool>(
        future: _isAdminWithFeatures(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data == true) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => _showAddCategoryDialog(context),
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                ),
                label: const Text(
                  'Add Category',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.category_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discussion Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                'Explore topics and join conversations',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, ForumCategory category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ForumCategoryScreen(category: category),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon container with gradient
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getCategoryColor(category.icon).withOpacity(0.8),
                        _getCategoryColor(category.icon),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _getCategoryColor(category.icon).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getCategoryIcon(category.icon),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        category.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildModernStatChip(
                            Icons.topic_rounded,
                            '${category.topicsCount}',
                            'Topics',
                            const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 12),
                          _buildModernStatChip(
                            Icons.chat_bubble_rounded,
                            '${category.postsCount}',
                            'Posts',
                            const Color(0xFF667EEA),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Column(
                  children: [
                    // Admin delete button
                    FutureBuilder<bool>(
                      future: _isAdminWithFeatures(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data == true) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.delete_rounded,
                                  color: Colors.red,
                                  size: 18,
                                ),
                              ),
                              onPressed: () => _showDeleteCategoryDialog(context, category),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    // Arrow icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667EEA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF667EEA),
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernStatChip(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String? iconName) {
    switch (iconName) {
      case 'math':
        return const Color(0xFF3B82F6);
      case 'science':
        return const Color(0xFF10B981);
      case 'literature':
        return const Color(0xFF8B5CF6);
      case 'history':
        return const Color(0xFFF59E0B);
      case 'technology':
        return const Color(0xFF06B6D4);
      case 'art':
        return const Color(0xFFEC4899);
      case 'music':
        return const Color(0xFF84CC16);
      case 'sports':
        return const Color(0xFFEF4444);
      case 'language':
        return const Color(0xFF6366F1);
      case 'general':
      default:
        return const Color(0xFF667EEA);
    }
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'math':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'literature':
        return Icons.book;
      case 'history':
        return Icons.history_edu;
      case 'technology':
        return Icons.computer;
      case 'art':
        return Icons.palette;
      case 'music':
        return Icons.music_note;
      case 'sports':
        return Icons.sports;
      case 'language':
        return Icons.translate;
      case 'general':
        return Icons.chat;
      default:
        return Icons.topic;
    }
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedIcon = 'general';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Category'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedIcon,
                      decoration: const InputDecoration(
                        labelText: 'Icon',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'general', child: Text('General')),
                        DropdownMenuItem(value: 'science', child: Text('Science')),
                        DropdownMenuItem(value: 'math', child: Text('Math')),
                        DropdownMenuItem(value: 'history', child: Text('History')),
                        DropdownMenuItem(value: 'technology', child: Text('Technology')),
                        DropdownMenuItem(value: 'art', child: Text('Art')),
                        DropdownMenuItem(value: 'music', child: Text('Music')),
                        DropdownMenuItem(value: 'sports', child: Text('Sports')),
                        DropdownMenuItem(value: 'language', child: Text('Language')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedIcon = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isNotEmpty &&
                        descriptionController.text.trim().isNotEmpty) {
                      try {
                        await context.read<ForumProvider>().createCategory(
                          nameController.text.trim(),
                          descriptionController.text.trim(),
                          selectedIcon,
                        );
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Category created successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to create category: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, ForumCategory category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text('Are you sure you want to delete "${category.name}"?\n\nThis action cannot be undone and will permanently delete:\n• The category\n• All topics in this category (${category.topicsCount})\n• All posts in those topics (${category.postsCount})\n\nThis is a destructive operation!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  print('Delete Category Dialog: Starting deletion of category ${category.id}');
                  await context.read<ForumProvider>().deleteCategory(category.id);
                  print('Delete Category Dialog: Deletion completed successfully');
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Category deleted successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  print('Delete Category Dialog: Error occurred: $e');
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete category: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete Forever'),
            ),
          ],
        );
      },
    );
  }
}

// Custom painter for geometric background pattern
class GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw geometric circles
    for (int i = 0; i < 5; i++) {
      final radius = (i + 1) * 20.0;
      final center = Offset(size.width * 0.8, size.height * 0.3);
      canvas.drawCircle(center, radius, paint);
    }

    // Draw geometric lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
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
