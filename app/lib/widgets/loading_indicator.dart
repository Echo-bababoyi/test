import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String? text;

  const LoadingIndicator({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFFFF6D00)),
          if (text != null) ...[
            const SizedBox(height: 16),
            Text(text!, style: const TextStyle(fontSize: 18, color: Color(0xFF999999))),
          ],
        ],
      ),
    );
  }
}
