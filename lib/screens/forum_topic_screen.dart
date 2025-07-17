import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/forum_provider.dart';
import '../providers/username_provider.dart';
import '../models/forum_topic.dart';
import '../models/forum_post.dart';

class ForumTopicScreen extends StatefulWidget {
  final ForumTopic topic;

  const ForumTopicScreen({
    super.key,
    required this.topic,
  });

  @override
  State<ForumTopicScreen> createState() => _ForumTopicScreenState();
}

class _ForumTopicScreenState extends State<ForumTopicScreen> {
  final _replyController = TextEditingController();
  bool _isReplying = false;
  String? _replyingToPostId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ForumProvider>().loadTopic(widget.topic.id);
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    if (_replyController.text.trim().isEmpty) return;

    setState(() {
      _isReplying = true;
    });

    try {
      final usernameProvider = context.read<UsernameProvider>();
      if (usernameProvider.currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set up your username first.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final post = await context.read<ForumProvider>().createPost(
        content: _replyController.text.trim(),
        topicId: widget.topic.id,
        authorId: usernameProvider.currentUserId!,
        parentPostId: _replyingToPostId,
      );

      if (post != null && mounted) {
        _replyController.clear();
        _replyingToPostId = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to post reply. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReplying = false;
        });
      }
    }
  }

  void _replyToPost(ForumPost post) {
    setState(() {
      _replyingToPostId = post.id;
    });
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reply to ${post.authorName}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  post.content,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _replyController,
                decoration: InputDecoration(
                  hintText: 'Write your reply...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 4,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _replyingToPostId = null;
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isReplying ? null : () {
                      Navigator.of(context).pop();
                      _submitReply();
                    },
                    child: _isReplying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Reply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.topic.title,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Username display
          Consumer<UsernameProvider>(
            builder: (context, usernameProvider, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        usernameProvider.currentUsername ?? 'User',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
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
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading topic',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    forumProvider.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => forumProvider.loadTopic(widget.topic.id),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final currentTopic = forumProvider.currentTopic ?? widget.topic;

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => forumProvider.loadTopic(widget.topic.id),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildTopicHeader(context, currentTopic),
                      const SizedBox(height: 24),
                      if (forumProvider.posts.isNotEmpty) ...[
                        Text(
                          'Replies (${forumProvider.posts.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...forumProvider.posts.map((post) => 
                          _buildPostCard(context, post)
                        ),
                      ] else ...[
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No replies yet',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Be the first to reply!',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (!currentTopic.isLocked) _buildReplySection(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopicHeader(BuildContext context, ForumTopic topic) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (topic.isPinned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.push_pin, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Pinned',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (topic.isLocked)
                  Container(
                    margin: EdgeInsets.only(left: topic.isPinned ? 8 : 0),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Locked',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (topic.isPinned || topic.isLocked) const SizedBox(height: 12),
            Text(
              topic.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              topic.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    topic.authorName.isNotEmpty ? topic.authorName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.authorName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDate(topic.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${topic.postsCount}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${topic.viewsCount}',
                          style: TextStyle(
                            fontSize: 14,
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
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, ForumPost post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDate(post.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (post.isEdited)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Edited',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                InkWell(
                  onTap: () {
                    final usernameProvider = context.read<UsernameProvider>();
                    if (usernameProvider.currentUserId != null) {
                      context.read<ForumProvider>().togglePostLike(
                        post.id, 
                        usernameProvider.currentUserId!
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.thumb_up_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.likesCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () => _replyToPost(post),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.reply,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplySection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _replyController,
                decoration: InputDecoration(
                  hintText: 'Write a reply...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: IconButton(
                onPressed: _isReplying ? null : _submitReply,
                icon: _isReplying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
