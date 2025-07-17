import 'package:flutter/foundation.dart';
import '../models/pdf_document.dart';
import '../services/pdf_service.dart';

class PdfProvider with ChangeNotifier {
  List<PdfDocument> _pdfs = [];
  List<PdfDocument> _filteredPdfs = [];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  List<PdfDocument> get pdfs => _filteredPdfs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  List<String> get categories => [
    'All',
    'Business',
    'Education',
    'Technology',
    'Science',
    'Health',
    'Entertainment',
    'Other'
  ];

  Future<void> loadPdfs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pdfs = await PdfService.getAllPdfs();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchPdfs(String query) async {
    _searchQuery = query;
    
    if (query.isEmpty) {
      _filteredPdfs = _selectedCategory == 'All' 
          ? _pdfs 
          : _pdfs.where((pdf) => pdf.category == _selectedCategory).toList();
    } else {
      _isLoading = true;
      _error = null;
      notifyListeners();

      try {
        final searchResults = await PdfService.searchPdfs(query);
        _filteredPdfs = _selectedCategory == 'All' 
            ? searchResults 
            : searchResults.where((pdf) => pdf.category == _selectedCategory).toList();
      } catch (e) {
        _error = e.toString();
      } finally {
        _isLoading = false;
      }
    }
    
    notifyListeners();
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    if (_selectedCategory == 'All') {
      _filteredPdfs = _pdfs;
    } else {
      _filteredPdfs = _pdfs.where((pdf) => pdf.category == _selectedCategory).toList();
    }
  }

  Future<void> addPdf(PdfDocument pdf) async {
    _pdfs.insert(0, pdf);
    _applyFilters();
    notifyListeners();
  }

  Future<void> deletePdf(String id) async {
    try {
      await PdfService.deletePdf(id);
      _pdfs.removeWhere((pdf) => pdf.id == id);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow; // Re-throw the exception so the UI can handle it
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
