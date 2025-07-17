import 'package:flutter/material.dart';
import '../models/forum_category.dart';
import '../models/forum_topic.dart';
import '../models/forum_post.dart';
import '../services/forum_service.dart';

class ForumProvider with ChangeNotifier {
  final ForumService _forumService = ForumService();

  List<ForumCategory> _categories = [];
  List<ForumTopic> _topics = [];
  List<ForumPost> _posts = [];
  ForumTopic? _currentTopic;
  
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ForumCategory> get categories => _categories;
  List<ForumTopic> get topics => _topics;
  List<ForumPost> get posts => _posts;
  ForumTopic? get currentTopic => _currentTopic;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load categories
  Future<void> loadCategories() async {
    print('ForumProvider: Starting to load categories...');
    _setLoading(true);
    try {
      print('ForumProvider: Calling forum service...');
      _categories = await _forumService.getCategories();
      print('ForumProvider: Got ${_categories.length} categories from service');
      _error = null;
    } catch (e) {
      print('ForumProvider: Error loading categories: $e');
      _error = 'Failed to load categories: $e';
    } finally {
      print('ForumProvider: Setting loading to false...');
      _setLoading(false);
    }
  }

  // Load topics for a category
  Future<void> loadTopics(String categoryId) async {
    print('ForumProvider: Starting to load topics for category $categoryId');
    _setLoading(true);
    try {
      print('ForumProvider: Calling forum service to get topics...');
      _topics = await _forumService.getTopics(categoryId);
      print('ForumProvider: Got ${_topics.length} topics from service');
      _error = null;
    } catch (e) {
      print('ForumProvider: Error loading topics: $e');
      _error = 'Failed to load topics: $e';
    } finally {
      print('ForumProvider: Setting loading to false for topics...');
      _setLoading(false);
    }
  }

  // Load topic details
  Future<void> loadTopic(String topicId) async {
    print('ForumProvider: Starting to load topic details for $topicId');
    _setLoading(true);
    try {
      print('ForumProvider: Calling forum service to get topic details...');
      _currentTopic = await _forumService.getTopic(topicId);
      if (_currentTopic != null) {
        print('ForumProvider: Topic loaded successfully: ${_currentTopic!.title}');
        print('ForumProvider: Loading posts for this topic...');
        await loadPosts(topicId);
      } else {
        print('ForumProvider: Topic loading returned null');
      }
      _error = null;
    } catch (e) {
      print('ForumProvider: Error loading topic: $e');
      _error = 'Failed to load topic: $e';
    } finally {
      print('ForumProvider: Setting loading to false for topic details...');
      _setLoading(false);
    }
  }

  // Load posts for a topic
  Future<void> loadPosts(String topicId) async {
    print('ForumProvider: Starting to load posts for topic $topicId');
    _setLoading(true);
    try {
      print('ForumProvider: Calling forum service to get posts...');
      _posts = await _forumService.getPosts(topicId);
      print('ForumProvider: Got ${_posts.length} posts from service');
      _error = null;
    } catch (e) {
      print('ForumProvider: Error loading posts: $e');
      _error = 'Failed to load posts: $e';
    } finally {
      print('ForumProvider: Setting loading to false for posts...');
      _setLoading(false);
    }
  }

  // Create new topic
  Future<ForumTopic?> createTopic({
    required String title,
    required String description,
    required String categoryId,
    required String authorId,
  }) async {
    print('ForumProvider: Creating topic "$title" in category $categoryId');
    _setLoading(true);
    try {
      final topic = await _forumService.createTopic(
        title: title,
        description: description,
        categoryId: categoryId,
        authorId: authorId,
      );
      
      if (topic != null) {
        print('ForumProvider: Topic created successfully, adding to local list');
        _topics.insert(0, topic);
        print('ForumProvider: Now have ${_topics.length} topics in list');
        notifyListeners();
      } else {
        print('ForumProvider: Topic creation returned null');
      }
      
      _error = null;
      return topic;
    } catch (e) {
      print('ForumProvider: Error creating topic: $e');
      _error = 'Failed to create topic: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Create new post
  Future<ForumPost?> createPost({
    required String content,
    required String topicId,
    required String authorId,
    String? parentPostId,
  }) async {
    print('ForumProvider: Creating post in topic $topicId by author $authorId');
    try {
      final post = await _forumService.createPost(
        content: content,
        topicId: topicId,
        authorId: authorId,
        parentPostId: parentPostId,
      );
      
      if (post != null) {
        print('ForumProvider: Post created successfully, adding to local list');
        _posts.add(post);
        print('ForumProvider: Now have ${_posts.length} posts in list');
        
        // Update topic post count
        if (_currentTopic != null && _currentTopic!.id == topicId) {
          _currentTopic = ForumTopic(
            id: _currentTopic!.id,
            title: _currentTopic!.title,
            description: _currentTopic!.description,
            categoryId: _currentTopic!.categoryId,
            authorId: _currentTopic!.authorId,
            authorName: _currentTopic!.authorName,
            createdAt: _currentTopic!.createdAt,
            updatedAt: _currentTopic!.updatedAt,
            postsCount: _currentTopic!.postsCount + 1,
            viewsCount: _currentTopic!.viewsCount,
            isPinned: _currentTopic!.isPinned,
            isLocked: _currentTopic!.isLocked,
            lastPostId: post.id,
            lastPostAuthor: post.authorName,
            lastPostAt: post.createdAt,
          );
        }
        
        notifyListeners();
      } else {
        print('ForumProvider: Post creation returned null');
      }
      
      _error = null;
      return post;
    } catch (e) {
      print('ForumProvider: Error creating post: $e');
      _error = 'Failed to create post: $e';
      return null;
    }
  }

  // Like/unlike post
  Future<void> togglePostLike(String postId, String userId) async {
    try {
      final isLiked = await _forumService.likePost(postId, userId);
      
      // Update local post like count
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        final newLikesCount = isLiked ? post.likesCount + 1 : post.likesCount - 1;
        
        _posts[postIndex] = ForumPost(
          id: post.id,
          content: post.content,
          topicId: post.topicId,
          authorId: post.authorId,
          authorName: post.authorName,
          createdAt: post.createdAt,
          updatedAt: post.updatedAt,
          parentPostId: post.parentPostId,
          likesCount: newLikesCount,
          isEdited: post.isEdited,
          attachments: post.attachments,
        );
        
        notifyListeners();
      }
      
      _error = null;
    } catch (e) {
      _error = 'Failed to toggle like: $e';
    }
  }

  // Update post
  Future<bool> updatePost(String postId, String content, String authorId) async {
    try {
      final success = await _forumService.updatePost(postId, content, authorId);
      
      if (success) {
        final postIndex = _posts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          final post = _posts[postIndex];
          _posts[postIndex] = ForumPost(
            id: post.id,
            content: content,
            topicId: post.topicId,
            authorId: post.authorId,
            authorName: post.authorName,
            createdAt: post.createdAt,
            updatedAt: DateTime.now(),
            parentPostId: post.parentPostId,
            likesCount: post.likesCount,
            isEdited: true,
            attachments: post.attachments,
          );
          
          notifyListeners();
        }
      }
      
      _error = null;
      return success;
    } catch (e) {
      _error = 'Failed to update post: $e';
      return false;
    }
  }

  // Delete post
  Future<bool> deletePost(String postId, String authorId) async {
    try {
      final success = await _forumService.deletePost(postId, authorId);
      
      if (success) {
        _posts.removeWhere((p) => p.id == postId);
        notifyListeners();
      }
      
      _error = null;
      return success;
    } catch (e) {
      _error = 'Failed to delete post: $e';
      return false;
    }
  }

  // Search topics
  Future<List<ForumTopic>> searchTopics(String query) async {
    try {
      final results = await _forumService.searchTopics(query);
      _error = null;
      return results;
    } catch (e) {
      _error = 'Failed to search topics: $e';
      return [];
    }
  }

  // Clear current data
  void clearTopics() {
    _topics = [];
    notifyListeners();
  }

  void clearPosts() {
    _posts = [];
    _currentTopic = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    print('ForumProvider: Setting loading to $loading, categories count: ${_categories.length}');
    _isLoading = loading;
    notifyListeners();
  }
}
