import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/orders_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../models/order_model.dart';

class SellerOrdersTab extends StatefulWidget {
  const SellerOrdersTab({super.key});

  @override
  State<SellerOrdersTab> createState() => _SellerOrdersTabState();
}

class _SellerOrdersTabState extends State<SellerOrdersTab> {
  String _selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _refreshOrders();
  }

  Future<void> _refreshOrders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);

    if (authProvider.currentSeller != null) {
      await ordersProvider.fetchSellerOrders(
        authProvider.currentSeller!.sellerId,
      );
      // Reapply the current filter after refreshing
      ordersProvider.setOrderStatusFilter(_selectedStatusFilter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.receipt_long,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Orders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
      ),
      body: Consumer2<OrdersProvider, AuthProvider>(
        builder: (context, ordersProvider, authProvider, child) {
          if (authProvider.currentSeller == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Please log in to view orders',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (ordersProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading orders...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (ordersProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${ordersProvider.errorMessage}',
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshOrders,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final orders = ordersProvider.sellerOrders;

          if (orders.isEmpty) {
            // Show different messages based on whether it's filtered or not
            final isFiltered = _selectedStatusFilter != 'All';
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isFiltered
                        ? Icons.filter_list_off
                        : Icons.receipt_long_outlined,
                    size: 120,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isFiltered
                        ? 'No $_selectedStatusFilter orders'
                        : 'No orders yet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isFiltered
                        ? 'No orders found with "$_selectedStatusFilter" status.\nTry selecting a different filter.'
                        : 'Customer orders will appear here',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  if (isFiltered) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedStatusFilter = 'All';
                        });
                        ordersProvider.setOrderStatusFilter('All');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Show All Orders'),
                    ),
                  ],
                ],
              ),
            );
          }

          return Column(
            children: [
              // Order Statistics
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildOrderStatistics(ordersProvider),
              ),

              // Debug info - show total orders and current filter
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Info:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    Text(
                      'Total orders in database: ${ordersProvider.allSellerOrders.length}',
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                    Text(
                      'Current filter: $_selectedStatusFilter',
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                    Text(
                      'Filtered orders count: ${orders.length}',
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                    if (ordersProvider.allSellerOrders.isNotEmpty)
                      Text(
                        'Available statuses: ${ordersProvider.allSellerOrders.map((o) => o.status).toSet().join(", ")}',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Status Filter
              Container(
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        [
                          'All',
                          'Pending',
                          'Confirmed',
                          'Preparing',
                          'Ready',
                          'Delivered',
                        ].map((status) {
                          final isSelected = _selectedStatusFilter == status;
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedStatusFilter = status;
                                });
                                ordersProvider.setOrderStatusFilter(status);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? Colors.orange
                                          : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? Colors.orange
                                            : Colors.grey[300]!,
                                  ),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.grey[700],
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Orders List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshOrders,
                  color: Colors.orange,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return SellerOrderCard(
                        order: order,
                        onStatusUpdate: _refreshOrders,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderStatistics(OrdersProvider ordersProvider) {
    final stats = ordersProvider.getOrderStatistics();
    final totalSales = ordersProvider.getTotalSales();

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Text(
                '${stats['total'] ?? 0}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Total Orders',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                '${stats['pending'] ?? 0}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Pending',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                '${stats['delivered'] ?? 0}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Delivered',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                '₹${totalSales.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'Total Sales',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SellerOrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onStatusUpdate;

  const SellerOrderCard({
    super.key,
    required this.order,
    required this.onStatusUpdate,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.kitchen;
      case 'ready':
        return Icons.done_all;
      case 'delivered':
        return Icons.delivery_dining;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  List<String> _getNextStatuses(String currentStatus) {
    switch (currentStatus.toLowerCase()) {
      case 'pending':
        return ['Confirmed', 'Cancelled'];
      case 'confirmed':
        return ['Preparing', 'Cancelled'];
      case 'preparing':
        return ['Ready', 'Cancelled'];
      case 'ready':
        return ['Delivered'];
      default:
        return [];
    }
  }

  Future<void> _updateOrderStatus(
    BuildContext context,
    String newStatus,
  ) async {
    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);

    final success = await ordersProvider.updateOrderStatus(
      order.orderId,
      newStatus,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Order status updated to $newStatus'
                : 'Failed to update order status: ${ordersProvider.errorMessage}',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        onStatusUpdate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.orderId.substring(0, 8)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(order.status),
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Product Info
            Row(
              children: [
                const Icon(Icons.shopping_bag, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.productName.isNotEmpty
                        ? order.productName
                        : 'Product Name',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Customer Info
            Row(
              children: [
                const Icon(Icons.person, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Customer ID: ${order.customerId.substring(0, 8)}...',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Quantity and Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_cart,
                      size: 20,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Qty: ${order.quantity}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                Text(
                  '₹${order.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Date
            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy - hh:mm a').format(order.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),

            // Action Buttons
            if (_getNextStatuses(order.status).isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children:
                    _getNextStatuses(order.status).map((status) {
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                            right:
                                _getNextStatuses(order.status).last == status
                                    ? 0
                                    : 8,
                          ),
                          child: ElevatedButton(
                            onPressed:
                                () => _updateOrderStatus(context, status),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  status == 'Cancelled'
                                      ? Colors.red
                                      : _getStatusColor(status),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
