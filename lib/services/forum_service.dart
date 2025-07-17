import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/forum_category.dart';
import '../models/forum_topic.dart';
import '../models/forum_post.dart';

class ForumService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Categories
  Future<List<ForumCategory>> getCategories() async {
    try {
      print('Fetching forum categories...');
      final response = await _supabase
          .from('forum_categories')
          .select('*')
          .order('name');

      print('Categories response: $response');

      final categories = <ForumCategory>[];
      
      for (final json in response as List) {
        print('Processing category: $json');
        
        // Get counts for this category
        final categoryId = json['id'];
        final topicsCount = await _getTopicsCountForCategory(categoryId);
        final postsCount = await _getPostsCountForCategory(categoryId);
        
        categories.add(ForumCategory.fromJson({
          ...json,
          'topics_count': topicsCount,
          'posts_count': postsCount,
        }));
      }

      print('Found ${categories.length} categories');
      return categories;
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  // Helper method to count topics in a category
  Future<int> _getTopicsCountForCategory(String categoryId) async {
    try {
      final response = await _supabase
          .from('forum_topics')
          .select('id')
          .eq('category_id', categoryId);
      return (response as List).length;
    } catch (e) {
      print('Error counting topics for category $categoryId: $e');
      return 0;
    }
  }

  // Helper method to count posts in a category
  Future<int> _getPostsCountForCategory(String categoryId) async {
    try {
      // First get all topic IDs for this category
      final topicsResponse = await _supabase
          .from('forum_topics')
          .select('id')
          .eq('category_id', categoryId);
      
      if ((topicsResponse as List).isEmpty) {
        return 0;
      }
      
      final topicIds = (topicsResponse as List).map((topic) => topic['id']).toList();
      
      // Then count posts for these topics
      final postsResponse = await _supabase
          .from('forum_posts')
          .select('id')
          .inFilter('topic_id', topicIds);
      
      return (postsResponse as List).length;
    } catch (e) {
      print('Error counting posts for category $categoryId: $e');
      return 0;
    }
  }

  // Helper method to count posts in a topic
  Future<int> _getPostsCountForTopic(String topicId) async {
    try {
      final response = await _supabase
          .from('forum_posts')
          .select('id')
          .eq('topic_id', topicId);
      return (response as List).length;
    } catch (e) {
      print('Error counting posts for topic $topicId: $e');
      return 0;
    }
  }

  // Helper method to count likes for a post
  Future<int> _getLikesCountForPost(String postId) async {
    try {
      final response = await _supabase
          .from('forum_post_likes')
          .select('id')
          .eq('post_id', postId);
      return (response as List).length;
    } catch (e) {
      print('Error counting likes for post $postId: $e');
      return 0;
    }
  }

  // Topics
  Future<List<ForumTopic>> getTopics(String categoryId, {int? limit}) async {
    try {
      print('ForumService: Fetching topics for category $categoryId');
      
      var query = _supabase
          .from('forum_topics')
          .select('''
            *,
            author_name:forum_users!author_id(display_name)
          ''')
          .eq('category_id', categoryId)
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      print('ForumService: Got ${(response as List).length} topics from database');

      final topics = <ForumTopic>[];
      
      for (final json in response as List) {
        print('ForumService: Processing topic: ${json['title']}');
        
        // Handle author name
        if (json['author_name'] is Map) {
          json['author_name'] = json['author_name']['display_name'];
        }

        // Get actual post count for this topic
        final topicId = json['id'];
        final postsCount = await _getPostsCountForTopic(topicId);

        // Set values with actual counts
        json['posts_count'] = postsCount;
        json['views_count'] = json['views_count'] ?? 0;
        json['last_post_id'] = json['last_post_id'];
        json['last_post_author'] = json['last_post_author'];
        json['last_post_at'] = json['last_post_at'];

        topics.add(ForumTopic.fromJson(json));
      }
      
      print('ForumService: Successfully parsed ${topics.length} topics');
      return topics;
    } catch (e) {
      print('Error fetching topics: $e');
      return [];
    }
  }

  Future<ForumTopic?> getTopic(String topicId) async {
    try {
      print('ForumService: Fetching single topic $topicId');
      
      final response = await _supabase
          .from('forum_topics')
          .select('''
            *,
            author_name:forum_users!author_id(display_name)
          ''')
          .eq('id', topicId)
          .single();

      print('ForumService: Topic fetch response: $response');

      // Increment view count
      await _supabase
          .from('forum_topics')
          .update({'views_count': (response['views_count'] ?? 0) + 1})
          .eq('id', topicId);

      // Handle author name
      if (response['author_name'] is Map) {
        response['author_name'] = response['author_name']['display_name'];
      }

      // Get actual posts count for this topic
      final postsCount = await _getPostsCountForTopic(topicId);

      // Set actual values
      response['posts_count'] = postsCount;
      response['views_count'] = (response['views_count'] ?? 0) + 1; // +1 for the increment

      final topic = ForumTopic.fromJson(response);
      print('ForumService: Topic fetched successfully: ${topic.title}');
      return topic;
    } catch (e) {
      print('Error fetching topic: $e');
      return null;
    }
  }

  Future<ForumTopic?> createTopic({
    required String title,
    required String description,
    required String categoryId,
    required String authorId,
  }) async {
    try {
      print('ForumService: Creating topic "$title" for author $authorId in category $categoryId');
      
      final response = await _supabase
          .from('forum_topics')
          .insert({
            'title': title,
            'description': description,
            'category_id': categoryId,
            'author_id': authorId,
          })
          .select('''
            *,
            author_name:forum_users!author_id(display_name)
          ''')
          .single();

      print('ForumService: Topic creation response: $response');

      // Handle author name
      if (response['author_name'] is Map) {
        response['author_name'] = response['author_name']['display_name'];
      }

      final topic = ForumTopic.fromJson(response);
      print('ForumService: Topic created successfully with ID: ${topic.id}');
      return topic;
    } catch (e) {
      print('Error creating topic: $e');
      return null;
    }
  }

    // Posts
  Future<List<ForumPost>> getPosts(String topicId, {int? limit, int? offset}) async {
    try {
      print('ForumService: Fetching posts for topic $topicId');
      
      var query = _supabase
          .from('forum_posts')
          .select('''
            *,
            author_name:forum_users!author_id(display_name)
          ''')
          .eq('topic_id', topicId)
          .order('created_at');

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 10) - 1);
      }

      final response = await query;
      print('ForumService: Got ${(response as List).length} posts from database');

      final posts = <ForumPost>[];
      
      for (final json in response as List) {
        final content = json['content']?.toString() ?? '';
        final preview = content.length > 50 ? content.substring(0, 50) + '...' : content;
        print('ForumService: Processing post: $preview');
        
        // Handle author name
        if (json['author_name'] is Map) {
          json['author_name'] = json['author_name']['display_name'];
        }

        // Get actual likes count for this post
        final postId = json['id'];
        final likesCount = await _getLikesCountForPost(postId);

        // Set actual likes count
        json['likes_count'] = likesCount;

        posts.add(ForumPost.fromJson(json));
      }
      
      print('ForumService: Successfully parsed ${posts.length} posts');
      return posts;
    } catch (e) {
      print('Error fetching posts: $e');
      return [];
    }
  }

  Future<ForumPost?> createPost({
    required String content,
    required String topicId,
    required String authorId,
    String? parentPostId,
  }) async {
    try {
      print('ForumService: Creating post for topic $topicId by author $authorId');
      final preview = content.length > 50 ? content.substring(0, 50) + '...' : content;
      print('ForumService: Post content: $preview');

      final response = await _supabase
          .from('forum_posts')
          .insert({
            'content': content,
            'topic_id': topicId,
            'author_id': authorId,
            'parent_post_id': parentPostId,
          })
          .select('''
            *,
            author_name:forum_users!author_id(display_name)
          ''')
          .single();

      print('ForumService: Post creation response: $response');

      // Handle author name
      if (response['author_name'] is Map) {
        response['author_name'] = response['author_name']['display_name'];
      }

      // Set default values
      response['likes_count'] = response['likes_count'] ?? 0;

      final post = ForumPost.fromJson(response);
      print('ForumService: Post created successfully with ID: ${post.id}');
      return post;
    } catch (e) {
      print('Error creating post: $e');
      return null;
    }
  }

  Future<bool> likePost(String postId, String userId) async {
    try {
      // Check if already liked
      final existing = await _supabase
          .from('forum_post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Unlike
        await _supabase
            .from('forum_post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
        return false;
      } else {
        // Like
        await _supabase
            .from('forum_post_likes')
            .insert({
              'post_id': postId,
              'user_id': userId,
            });
        return true;
      }
    } catch (e) {
      print('Error toggling like: $e');
      return false;
    }
  }

  Future<bool> updatePost(String postId, String content, String authorId) async {
    try {
      await _supabase
          .from('forum_posts')
          .update({
            'content': content,
            'is_edited': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', postId)
          .eq('author_id', authorId);

      return true;
    } catch (e) {
      print('Error updating post: $e');
      return false;
    }
  }

  Future<bool> deletePost(String postId, String authorId) async {
    try {
      await _supabase
          .from('forum_posts')
          .delete()
          .eq('id', postId)
          .eq('author_id', authorId);

      return true;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  // Search
  Future<List<ForumTopic>> searchTopics(String query) async {
    try {
      print('ForumService: Searching topics with query: $query');
      
      final response = await _supabase
          .from('forum_topics')
          .select('''
            *,
            author_name:forum_users!author_id(display_name)
          ''')
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false)
          .limit(20);

      print('ForumService: Got ${(response as List).length} search results');

      final topics = <ForumTopic>[];
      
      for (final json in response as List) {
        print('ForumService: Processing search result: ${json['title']}');
        
        // Handle author name
        if (json['author_name'] is Map) {
          json['author_name'] = json['author_name']['display_name'];
        }

        // Get actual posts count for this topic
        final topicId = json['id'];
        final postsCount = await _getPostsCountForTopic(topicId);

        // Set actual values
        json['posts_count'] = postsCount;
        json['views_count'] = json['views_count'] ?? 0;

        topics.add(ForumTopic.fromJson(json));
      }
      
      return topics;
    } catch (e) {
      print('Error searching topics: $e');
      return [];
    }
  }
}
