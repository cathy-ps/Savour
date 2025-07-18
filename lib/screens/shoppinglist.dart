import 'package:flutter/material.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping List')),
      body: const Center(
        child: Text('Your Shopping List', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
