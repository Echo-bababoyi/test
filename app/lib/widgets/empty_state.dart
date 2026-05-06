import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const EmptyState({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: const Color(0xFFCCCCCC)),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(fontSize: 18, color: Color(0xFF999999))),
        ],
      ),
    );
  }
}
