import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/order_model.dart';
import '../config/supabase_config.dart';

class OrdersProvider with ChangeNotifier {
  final SupabaseClient _supabase = SupabaseConfig.client;

  List<OrderModel> _customerOrders = [];
  List<OrderModel> _sellerOrders = [];
  List<OrderModel> _filteredSellerOrders = [];
  String _orderStatusFilter = 'All';
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<OrderModel> get customerOrders => _customerOrders;
  List<OrderModel> get sellerOrders => _filteredSellerOrders;
  String get orderStatusFilter => _orderStatusFilter;
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

  // Fetch orders for customer
  Future<void> fetchCustomerOrders(String customerId) async {
    _setLoading(true);
    try {
      final response = await _supabase
          .from('orders')
          .select('*, products(*), sellers(*)')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      _customerOrders =
          response
              .map<OrderModel>((json) => OrderModel.fromJson(json))
              .toList();
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
  }

  // Fetch orders for seller
  Future<void> fetchSellerOrders(String sellerId) async {
    _setLoading(true);
    try {
      final response = await _supabase
          .from('orders')
          .select('*, products(*), users(*)')
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      _sellerOrders =
          response
              .map<OrderModel>((json) => OrderModel.fromJson(json))
              .toList();
      _applyStatusFilter();
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    }
    _setLoading(false);
  }

  // Create new order
  Future<bool> createOrder({
    required String customerId,
    required String sellerId,
    required String productId,
    required int quantity,
    required double totalPrice,
    String? deliveryLocation,
  }) async {
    _setLoading(true);
    try {
      final orderData = OrderModel(
        orderId: '',
        customerId: customerId,
        sellerId: sellerId,
        productId: productId,
        productName: '', // Will be filled from database response
        sellerName: '', // Will be filled from database response
        quantity: quantity,
        totalPrice: totalPrice,
        deliveryLocation: deliveryLocation,
        status: 'Pending',
        createdAt: DateTime.now(),
      );

      final response =
          await _supabase
              .from('orders')
              .insert(orderData.toInsertJson())
              .select('*, products(*), sellers(*)')
              .single();

      final newOrder = OrderModel.fromJson(response);
      _customerOrders.insert(0, newOrder);

      _setError(null);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    _setLoading(true);
    try {
      await _supabase
          .from('orders')
          .update({'status': status})
          .eq('order_id', orderId);

      // Update local order list
      final orderIndex = _sellerOrders.indexWhere(
        (order) => order.orderId == orderId,
      );
      if (orderIndex != -1) {
        _sellerOrders[orderIndex] = _sellerOrders[orderIndex].copyWith(
          status: status,
        );
        _applyStatusFilter();
      }

      // Update customer orders if it exists
      final customerOrderIndex = _customerOrders.indexWhere(
        (order) => order.orderId == orderId,
      );
      if (customerOrderIndex != -1) {
        _customerOrders[customerOrderIndex] =
            _customerOrders[customerOrderIndex].copyWith(status: status);
        _safeNotifyListeners();
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

  // Set order status filter for seller
  void setOrderStatusFilter(String status) {
    _orderStatusFilter = status;
    _applyStatusFilter();
  }

  // Apply status filter
  void _applyStatusFilter() {
    if (_orderStatusFilter == 'All') {
      _filteredSellerOrders = List.from(_sellerOrders);
    } else {
      _filteredSellerOrders =
          _sellerOrders
              .where((order) => order.status == _orderStatusFilter)
              .toList();
    }
    _safeNotifyListeners();
  }

  // Get order details with product and customer/seller info
  Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    try {
      final response =
          await _supabase
              .from('orders')
              .select('*, products(*), users(*), sellers(*)')
              .eq('order_id', orderId)
              .single();

      return response;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  // Subscribe to real-time order updates
  void subscribeToOrderUpdates(String userId, bool isSeller) {
    final column = isSeller ? 'seller_id' : 'customer_id';

    _supabase
        .from('orders')
        .stream(primaryKey: ['order_id'])
        .eq(column, userId)
        .listen((List<Map<String, dynamic>> data) {
          if (isSeller) {
            _sellerOrders =
                data
                    .map<OrderModel>((json) => OrderModel.fromJson(json))
                    .toList();
            _applyStatusFilter();
          } else {
            _customerOrders =
                data
                    .map<OrderModel>((json) => OrderModel.fromJson(json))
                    .toList();
            _safeNotifyListeners();
          }
        });
  }

  // Get order statistics for seller
  Map<String, int> getOrderStatistics() {
    final pending =
        _sellerOrders.where((order) => order.status == 'Pending').length;
    final delivered =
        _sellerOrders.where((order) => order.status == 'Delivered').length;
    final total = _sellerOrders.length;

    return {'pending': pending, 'delivered': delivered, 'total': total};
  }

  // Get total sales for seller
  double getTotalSales() {
    return _sellerOrders
        .where((order) => order.status == 'Delivered')
        .fold(0.0, (sum, order) => sum + order.totalPrice);
  }

  // Mark order as delivered
  Future<bool> markOrderAsDelivered(String orderId) async {
    return await updateOrderStatus(orderId, 'Delivered');
  }

  // Cancel order (for customers)
  Future<bool> cancelOrder(String orderId) async {
    _setLoading(true);
    try {
      await _supabase.from('orders').delete().eq('order_id', orderId);

      _customerOrders.removeWhere((order) => order.orderId == orderId);
      _sellerOrders.removeWhere((order) => order.orderId == orderId);
      _applyStatusFilter();

      _setError(null);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
}
