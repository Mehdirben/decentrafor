import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'providers/pdf_provider.dart';
import 'screens/pdf_store_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => PdfProvider()),
      ],
      child: MaterialApp(
        title: 'PDF Store',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const TestDataScreen(),
      ),
    );
  }
}

class TestDataScreen extends StatefulWidget {
  const TestDataScreen({super.key});

  @override
  State<TestDataScreen> createState() => _TestDataScreenState();
}

class _TestDataScreenState extends State<TestDataScreen> {
  bool _isLoading = false;
  String _message = '';

  Future<void> _addTestPdf() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final client = Supabase.instance.client;
      
      // Add a sample PDF entry
      await client.from('pdfs').insert({
        'title': 'Sample PDF Document',
        'description': 'This is a sample PDF document for testing the PDF store app. It demonstrates how PDFs are displayed in the app.',
        'file_name': 'sample_document.pdf',
        'file_url': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
        'file_size': 13264, // Size in bytes
        'category': 'Technology',
        'tags': ['sample', 'test', 'demo'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      setState(() {
        _message = 'Test PDF added successfully!';
      });
    } catch (e) {
      setState(() {
        _message = 'Error adding test PDF: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addMultipleTestPdfs() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final client = Supabase.instance.client;
      
      // Add multiple sample PDFs
      final testPdfs = [
        {
          'title': 'Flutter Development Guide',
          'description': 'A comprehensive guide to Flutter development covering widgets, state management, and best practices.',
          'file_name': 'flutter_guide.pdf',
          'file_url': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          'file_size': 2450000,
          'category': 'Technology',
          'tags': ['flutter', 'development', 'guide'],
        },
        {
          'title': 'Business Strategy 2024',
          'description': 'Annual business strategy document outlining goals, objectives, and key performance indicators.',
          'file_name': 'business_strategy_2024.pdf',
          'file_url': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          'file_size': 1890000,
          'category': 'Business',
          'tags': ['strategy', 'business', '2024'],
        },
        {
          'title': 'Introduction to Machine Learning',
          'description': 'Educational material covering the basics of machine learning algorithms and applications.',
          'file_name': 'ml_intro.pdf',
          'file_url': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          'file_size': 3200000,
          'category': 'Education',
          'tags': ['machine learning', 'education', 'ai'],
        },
        {
          'title': 'Health and Wellness Report',
          'description': 'Annual health and wellness report with statistics and recommendations for healthy living.',
          'file_name': 'health_wellness_2024.pdf',
          'file_url': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          'file_size': 1560000,
          'category': 'Health',
          'tags': ['health', 'wellness', 'report'],
        },
        {
          'title': 'Science Research Paper',
          'description': 'Research paper on renewable energy sources and their impact on climate change.',
          'file_name': 'renewable_energy_research.pdf',
          'file_url': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          'file_size': 4100000,
          'category': 'Science',
          'tags': ['research', 'renewable energy', 'climate'],
        }
      ];

      for (var pdf in testPdfs) {
        await client.from('pdfs').insert({
          ...pdf,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      
      setState(() {
        _message = '${testPdfs.length} test PDFs added successfully!';
      });
    } catch (e) {
      setState(() {
        _message = 'Error adding test PDFs: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearTestData() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final client = Supabase.instance.client;
      await client.from('pdfs').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      
      setState(() {
        _message = 'All test data cleared!';
      });
    } catch (e) {
      setState(() {
        _message = 'Error clearing test data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Store - Test Data'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test Data Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            const Text(
              'Add test PDFs to your database to test the app functionality:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _addTestPdf,
              child: const Text('Add Single Test PDF'),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _addMultipleTestPdfs,
              child: const Text('Add Multiple Test PDFs'),
            ),
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _clearTestData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear All Test Data'),
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const PdfStoreScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Go to PDF Store'),
            ),
            const SizedBox(height: 24),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            
            if (_message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _message.contains('Error') ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _message,
                  style: TextStyle(
                    color: _message.contains('Error') ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Note: Make sure you have run the SQL setup script in your Supabase dashboard first!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
