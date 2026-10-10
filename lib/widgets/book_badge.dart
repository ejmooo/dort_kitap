// BookBadge: kitaba göre renklendirilmiş, yuvarlatılmış kimlik rozeti.

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class BookBadge extends StatelessWidget {
  final String book;
  final bool large;

  const BookBadge({super.key, required this.book, this.large = false});

  @override
  Widget build(BuildContext context) {
    final baseColor = BookPalette.accent(book);
    final color = Theme.of(context).brightness == Brightness.dark
        ? Color.lerp(baseColor, Colors.white, .5)!
        : baseColor;
    final dotSize = large ? 10.0 : 8.0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 12,
        vertical: large ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: large ? 10 : 8),
          Flexible(
            child: Text(
              BookPalette.label(book),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: large ? 16 : 13,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
