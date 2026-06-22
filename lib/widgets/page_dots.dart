// PageDots: yatay sayfa konumunu gösteren animasyonlu nokta göstergesi.

import 'package:flutter/material.dart';

class PageDots extends StatelessWidget {
  final int count;
  final int currentIndex;
  final Color? activeColor;

  const PageDots({
    super.key,
    required this.count,
    required this.currentIndex,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = activeColor ?? scheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive ? active : scheme.onSurface.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
