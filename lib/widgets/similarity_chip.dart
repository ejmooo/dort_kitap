// SimilarityChip: bir temanın benzerlik düzeyini (tematik / neredeyse aynı /
// birebir) tarafsız bir dille gösteren etiket.

import 'package:flutter/material.dart';

class SimilarityChip extends StatelessWidget {
  final String similarity;

  const SimilarityChip({super.key, required this.similarity});

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = _meta();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  (String, IconData, Color) _meta() {
    switch (similarity) {
      case 'identical':
        return ('Birebir örtüşme', Icons.check_circle_outline, const Color(0xFF2E7D32));
      case 'near_identical':
        return ('Neredeyse aynı', Icons.compare_arrows, const Color(0xFF1565C0));
      case 'thematic':
      default:
        return ('Tematik benzerlik', Icons.auto_awesome_outlined, const Color(0xFF8E6BAA));
    }
  }
}
