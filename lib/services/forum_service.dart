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

      final categories = (response as List)
          .map((json) {
            print('Processing category: $json');
            return ForumCategory.fromJson({
              ...json,
              'topics_count': 0,
              'posts_count': 0,
            });
          })
          .toList();

      print('Found ${categories.length} categories');
      return categories;
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
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

      final topics = (response as List).map((json) {
        print('ForumService: Processing topic: ${json['title']}');
        
        // Handle author name
        if (json['author_name'] is Map) {
          json['author_name'] = json['author_name']['display_name'];
        }

        // For now, set default values for posts_count and other fields
        // We can add these counts separately if needed
        json['posts_count'] = json['posts_count'] ?? 0;
        json['views_count'] = json['views_count'] ?? 0;
        json['last_post_id'] = json['last_post_id'];
        json['last_post_author'] = json['last_post_author'];
        json['last_post_at'] = json['last_post_at'];

        return ForumTopic.fromJson(json);
      }).toList();
      
      print('ForumService: Successfully parsed ${topics.length} topics');
      return topics;
    } catch (e) {
      print('Error fetching topics: $e');
      return [];
    }
  }

  Future<ForumTopic?> getTopic(String topicId) async {
    try {
      final response = await _supabase
          .from('forum_topics')
          .select('''
            *,
            author_name:forum_users!author_id(display_name),
            posts_count:forum_posts(count)
          ''')
          .eq('id', topicId)
          .single();

      // Increment view count
      await _supabase
          .from('forum_topics')
          .update({'views_count': (response['views_count'] ?? 0) + 1})
          .eq('id', topicId);

      // Handle author name
      if (response['author_name'] is Map) {
        response['author_name'] = response['author_name']['display_name'];
      }

      return ForumTopic.fromJson(response);
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
      var query = _supabase
          .from('forum_posts')
          .select('''
            *,
            author_name:forum_users!author_id(display_name),
            likes_count:forum_post_likes(count)
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

      return (response as List).map((json) {
        // Handle author name
        if (json['author_name'] is Map) {
          json['author_name'] = json['author_name']['display_name'];
        }

        return ForumPost.fromJson(json);
      }).toList();
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

      // Handle author name
      if (response['author_name'] is Map) {
        response['author_name'] = response['author_name']['display_name'];
      }

      return ForumPost.fromJson(response);
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
      final response = await _supabase
          .from('forum_topics')
          .select('''
            *,
            author_name:forum_users!author_id(display_name),
            posts_count:forum_posts(count)
          ''')
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false)
          .limit(20);

      return (response as List).map((json) {
        // Handle author name
        if (json['author_name'] is Map) {
          json['author_name'] = json['author_name']['display_name'];
        }

        return ForumTopic.fromJson(json);
      }).toList();
    } catch (e) {
      print('Error searching topics: $e');
      return [];
    }
  }
}
