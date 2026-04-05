import 'package:flutter/material.dart';

/// Diagnostic version — no custom imports. Tests only that the route renders.
class ButtonPreview extends StatelessWidget {
  const ButtonPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A003A), // deep purple — unmistakable
      body: const Center(
        child: Text(
          'ROUTE OK',
          style: TextStyle(
            color: Color(0xFF00F5A0),
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
