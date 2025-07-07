import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product_model.dart';
import '../config/supabase_config.dart';

class ProductsProvider with ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;

  List<ProductModel> _products = [];
  List<ProductModel> _sellerProducts = [];
  List<ProductModel> _filteredProducts = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<ProductModel> get products => _filteredProducts;
  List<ProductModel> get sellerProducts => _sellerProducts;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    _safeNotifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    _safeNotifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    try {
      // Check if we can safely notify listeners
      if (!hasListeners) return;

      // Use post frame callback if called during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (hasListeners) {
            notifyListeners();
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Deferred notifyListeners error: $e');
          }
        }
      });
    } catch (e) {
      // Handle the case where notifyListeners is called after dispose
      if (kDebugMode) {
        debugPrint('Error in notifyListeners: $e');
      }
    }
  }

  // Fetch all products for customers
  Future<void> fetchProducts() async {
    _setLoading(true);
    try {
      final response = await _supabase
          .from('products')
          .select()
          .order('created_at', ascending: false);

      _products =
          response
              .map<ProductModel>((json) => ProductModel.fromJson(json))
              .toList();
      _applyFilters();
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
  }

  // Fetch products for a specific seller
  Future<void> fetchSellerProducts(String sellerId) async {
    _setLoading(true);
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      _sellerProducts =
          response
              .map<ProductModel>((json) => ProductModel.fromJson(json))
              .toList();
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
  }

  // Get product with seller info
  Future<Map<String, dynamic>?> getProductWithSeller(String productId) async {
    try {
      final response =
          await _supabase
              .from('products')
              .select('*, sellers!inner(*)')
              .eq('product_id', productId)
              .single();

      return response;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  // Add new product
  Future<bool> addProduct(ProductModel product) async {
    _setLoading(true);
    try {
      final response =
          await _supabase
              .from('products')
              .insert(product.toInsertJson())
              .select()
              .single();

      final newProduct = ProductModel.fromJson(response);
      _sellerProducts.insert(0, newProduct);
      _setError(null);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update product
  Future<bool> updateProduct(ProductModel product) async {
    _setLoading(true);
    try {
      await _supabase
          .from('products')
          .update(product.toInsertJson())
          .eq('product_id', product.productId);

      final index = _sellerProducts.indexWhere(
        (p) => p.productId == product.productId,
      );
      if (index != -1) {
        _sellerProducts[index] = product;
      }

      _setError(null);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Delete product
  Future<bool> deleteProduct(String productId) async {
    _setLoading(true);
    try {
      await _supabase.from('products').delete().eq('product_id', productId);

      _sellerProducts.removeWhere((p) => p.productId == productId);
      _setError(null);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Set category filter
  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  // Apply filters and search
  void _applyFilters() {
    _filteredProducts =
        _products.where((product) {
          bool matchesCategory =
              _selectedCategory == 'All' ||
              product.category == _selectedCategory;
          bool matchesSearch =
              _searchQuery.isEmpty ||
              product.name.toLowerCase().contains(_searchQuery.toLowerCase());

          return matchesCategory && matchesSearch;
        }).toList();

    _safeNotifyListeners();
  }

  // Get seller status for product
  Future<String> getSellerStatus(String sellerId) async {
    try {
      final response =
          await _supabase
              .from('sellers')
              .select('is_online')
              .eq('seller_id', sellerId)
              .single();

      return response['is_online'] == true ? 'online' : 'offline';
    } catch (e) {
      return 'offline';
    }
  }

  // Update product stock after order
  Future<void> updateProductStock(String productId, int newStock) async {
    try {
      await _supabase
          .from('products')
          .update({'stock': newStock})
          .eq('product_id', productId);

      // Update local product list
      final productIndex = _products.indexWhere(
        (p) => p.productId == productId,
      );
      if (productIndex != -1) {
        _products[productIndex] = _products[productIndex].copyWith(
          stock: newStock,
        );
        _applyFilters();
      }

      final sellerProductIndex = _sellerProducts.indexWhere(
        (p) => p.productId == productId,
      );
      if (sellerProductIndex != -1) {
        _sellerProducts[sellerProductIndex] =
            _sellerProducts[sellerProductIndex].copyWith(stock: newStock);
        _safeNotifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<ProductModel?> getProductById(String productId) async {
    try {
      final response =
          await _supabase
              .from('products')
              .select()
              .eq('product_id', productId)
              .single();

      return ProductModel.fromJson(response);
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }
}
