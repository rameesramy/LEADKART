import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/providers/products_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/orders_provider.dart';
import '../../../models/product_model.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  ProductModel? product;
  bool isLoading = true;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final productsProvider = Provider.of<ProductsProvider>(
        context,
        listen: false,
      );
      final loadedProduct = await productsProvider.getProductById(
        widget.productId,
      );
      setState(() {
        product = loadedProduct;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _orderProduct() async {
    if (product == null) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentCustomer;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to place an order'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if enough stock is available
      if (quantity > product!.stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Only ${product!.stock} items available in stock'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading
      setState(() {
        isLoading = true;
      });

      final ordersProvider = Provider.of<OrdersProvider>(
        context,
        listen: false,
      );
      final productsProvider = Provider.of<ProductsProvider>(
        context,
        listen: false,
      );

      // Create order in database
      final success = await ordersProvider.createOrder(
        customerId: currentUser.userId,
        sellerId: product!.sellerId,
        productId: product!.productId,
        quantity: quantity,
        totalPrice: product!.price * quantity,
        deliveryLocation:
            null, // Can be added later with a delivery address input
      );

      if (success) {
        // Update product stock
        final newStock = product!.stock - quantity;
        await productsProvider.updateProductStock(product!.productId, newStock);

        // Update local product
        setState(() {
          product = product!.copyWith(stock: newStock);
          quantity = 1; // Reset quantity
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to place order: ${ordersProvider.errorMessage}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error placing order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: Colors.blue,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : product == null
              ? const Center(
                child: Text(
                  'Product not found',
                  style: TextStyle(fontSize: 18),
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    SizedBox(
                      height: 300,
                      width: double.infinity,
                      child:
                          product!.imageUrl != null &&
                                  product!.imageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                imageUrl: product!.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 60,
                                      ),
                                    ),
                              )
                              : Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Name
                          Text(
                            product!.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Price
                          Text(
                            '₹${product!.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Stock Status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  product!.isInStock
                                      ? Colors.green
                                      : Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              product!.isInStock ? 'In Stock' : 'Out of Stock',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          if (product!.description != null &&
                              product!.description!.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  product!.description!,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),

                          // Category
                          Row(
                            children: [
                              const Text(
                                'Category: ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                product!.category,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Quantity Selector
                          if (product!.isInStock)
                            Column(
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Quantity: ',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed:
                                          quantity > 1
                                              ? () {
                                                setState(() {
                                                  quantity--;
                                                });
                                              }
                                              : null,
                                      icon: const Icon(Icons.remove),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        quantity.toString(),
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          quantity++;
                                        });
                                      },
                                      icon: const Icon(Icons.add),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Total Price
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue[200]!,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total:',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '₹${(product!.price * quantity).toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      bottomNavigationBar:
          product != null && product!.isInStock
              ? Container(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _orderProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Place Order',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
              : null,
    );
  }
}
