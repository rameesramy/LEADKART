import 'package:flutter/material.dart';

class MyProductsTab extends StatelessWidget {
  const MyProductsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: null,
      body: Center(
        child: Text(
          'My Products Tab - Seller products will be displayed here',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
