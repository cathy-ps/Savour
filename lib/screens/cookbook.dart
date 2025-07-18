import 'package:flutter/material.dart';

class CookbookScreen extends StatelessWidget {
  const CookbookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cookbook')),
      body: const Center(
        child: Text('Your Cookbook', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
