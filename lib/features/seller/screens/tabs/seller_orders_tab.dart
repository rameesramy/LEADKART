import 'package:flutter/material.dart';

class SellerOrdersTab extends StatelessWidget {
  const SellerOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: null,
      body: Center(
        child: Text(
          'Seller Orders Tab - Customer orders will be displayed here',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
