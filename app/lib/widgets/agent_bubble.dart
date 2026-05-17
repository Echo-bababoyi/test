import 'package:flutter/material.dart';

const _kOrange = Color(0xFFFF6D00);

class AgentBubble extends StatelessWidget {
  final String text;
  final bool isAgent;

  const AgentBubble({super.key, required this.text, required this.isAgent});

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.72;
    final borderRadius = isAgent
        ? const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(14),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(14),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      child: Row(
        mainAxisAlignment:
            isAgent ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAgent) ...[
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2, right: 6),
              decoration: const BoxDecoration(
                color: _kOrange,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text(
                '浙',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: isAgent
                    ? const Color(0xFFFFF0E6)
                    : _kOrange.withValues(alpha: 0.08),
                borderRadius: borderRadius,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                text,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
