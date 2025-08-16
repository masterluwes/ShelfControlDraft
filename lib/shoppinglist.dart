import 'package:flutter/material.dart';

class Shoppinglist extends StatelessWidget {
  const Shoppinglist({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Shopping List goes here',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
      ),
    );
  }
}
