// SimilarityChip: bir temanın benzerlik düzeyini (tematik / neredeyse aynı /
// birebir) tarafsız bir dille gösteren etiket. Editöryel: küçük nokta + harf
// aralıklı büyük harf etiket, ince çerçeve.

import 'package:flutter/material.dart';

class SimilarityChip extends StatelessWidget {
  final String similarity;

  const SimilarityChip({super.key, required this.similarity});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _meta();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color) _meta() {
    switch (similarity) {
      case 'identical':
        return ('Birebir örtüşme', const Color(0xFF9A6A2E)); // pirinç
      case 'near_identical':
        return ('Neredeyse aynı', const Color(0xFF2F7E73)); // teal
      case 'thematic':
      default:
        return ('Tematik benzerlik', const Color(0xFF7E5A86)); // erik
    }
  }
}
