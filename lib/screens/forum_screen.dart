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
  
  Future<bool> _isAdminWithFeatures() async {
    final adminFeaturesEnabled = await AdminFeaturesService.isEnabled();
    final usernameProvider = Provider.of<UsernameProvider>(context, listen: false);
    return usernameProvider.isAdmin && adminFeaturesEnabled;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ForumProvider>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1F2937),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  'Education Forum',
                  style: TextStyle(
                    color: innerBoxIsScrolled ? const Color(0xFF1F2937) : Colors.white,
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
                        color: innerBoxIsScrolled 
                            ? const Color(0xFF667EEA).withOpacity(0.1)
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: innerBoxIsScrolled 
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
                            color: innerBoxIsScrolled 
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
                                color: innerBoxIsScrolled 
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
                        color: innerBoxIsScrolled 
                            ? const Color(0xFF667EEA).withOpacity(0.1)
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: innerBoxIsScrolled 
                              ? const Color(0xFF667EEA).withOpacity(0.3)
                              : Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.search_rounded,
                        color: innerBoxIsScrolled 
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Something went wrong',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      forumProvider.error!,
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => forumProvider.loadCategories(),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            }

            if (forumProvider.categories.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No forum categories available',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Check back later for discussions!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => forumProvider.loadCategories(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildWelcomeCard(context),
                  const SizedBox(height: 20),
                  Text(
                    'Discussion Categories',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...forumProvider.categories.map((category) => 
                    _buildCategoryCard(context, category)
                  ),
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
            return FloatingActionButton.extended(
              onPressed: () => _showAddCategoryDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.school,
                    size: 32,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Welcome to the Education Forum!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Connect with fellow learners, ask questions, share knowledge, and engage in meaningful educational discussions.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, ForumCategory category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ForumCategoryScreen(category: category),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(category.icon),
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatChip(
                          context,
                          Icons.topic,
                          '${category.topicsCount} topics',
                        ),
                        const SizedBox(width: 8),
                        _buildStatChip(
                          context,
                          Icons.chat_bubble_outline,
                          '${category.postsCount} posts',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Admin delete button
              FutureBuilder<bool>(
                future: _isAdminWithFeatures(),
                builder: (context, snapshot) {
                  print('Category Card: Admin features enabled = ${snapshot.data}, Loading = ${snapshot.connectionState == ConnectionState.waiting}');
                  if (snapshot.hasData && snapshot.data == true) {
                    return IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => _showDeleteCategoryDialog(context, category),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
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
