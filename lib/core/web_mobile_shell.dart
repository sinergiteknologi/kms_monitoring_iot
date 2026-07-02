import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WebMobileShell extends StatelessWidget {
  final Widget child;

  const WebMobileShell({super.key, required this.child});

  static const double maxWidth = 430;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    return ColoredBox(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Container(
          width: maxWidth,
          constraints: const BoxConstraints(maxHeight: 920),
          margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FC),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ),
    );
  }
}
