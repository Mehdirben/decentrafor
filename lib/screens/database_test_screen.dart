import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseTestScreen extends StatefulWidget {
  const DatabaseTestScreen({super.key});

  @override
  State<DatabaseTestScreen> createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends State<DatabaseTestScreen> {
  String _result = 'Testing database...';
  
  @override
  void initState() {
    super.initState();
    _testDatabase();
  }

  Future<void> _testDatabase() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Test if forum_categories table exists and has data
      final categoriesResponse = await supabase
          .from('forum_categories')
          .select('*')
          .limit(5);
      
      setState(() {
        _result = 'Categories found: ${categoriesResponse.length}\n\n';
        for (var category in categoriesResponse) {
          _result += '- ${category['name']}: ${category['description']}\n';
        }
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Database Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Database Test Results:',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_result),
              ),
            ),
            ElevatedButton(
              onPressed: _testDatabase,
              child: const Text('Test Again'),
            ),
          ],
        ),
      ),
    );
  }
}
