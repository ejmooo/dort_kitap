import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Short, event-driven motion; never runs a perpetual animation.
abstract final class AtlasMotion {
  static Duration duration(BuildContext context, [int milliseconds = 280]) =>
      MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : Duration(milliseconds: milliseconds);

  static void goToPage(
    BuildContext context,
    PageController controller,
    int index,
  ) {
    if (!controller.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.jumpToPage(index);
    } else {
      controller.animateToPage(
        index,
        duration: duration(context),
        curve: Curves.easeOutCubic,
      );
    }
  }

  static void selection() => HapticFeedback.selectionClick();
}

/// Replays only when its identity changes, preserving the child's state.
class AtlasEntrance extends StatelessWidget {
  const AtlasEntrance({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: AtlasMotion.duration(context, 360),
    curve: Curves.easeOutCubic,
    child: child,
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 12 * (1 - value)),
        child: child,
      ),
    ),
  );
}

/// Decorative, equal-weight paths for the four traditions. No image downloads,
/// blur layers, or animation tickers are needed.
class AtlasMark extends StatelessWidget {
  const AtlasMark({super.key, this.size = 120});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: const _AtlasPainter(),
      ),
    ),
  );
}

class _AtlasPainter extends CustomPainter {
  const _AtlasPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width / 85;
    const colors = [
      Color(0xFFF2BF91),
      Color(0xFFC7B7F0),
      Color(0xFFAAD5CD),
      Color(0xFFEAE3B0),
    ];
    for (var i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * .43,
          height: size.height * .88,
        ),
        paint,
      );
      canvas.rotate(0.7853981634);
    }
    canvas.drawCircle(
      Offset.zero,
      size.width * .035,
      Paint()..color = const Color(0xFFF2BF91),
    );
  }

  @override
  bool shouldRepaint(_AtlasPainter oldDelegate) => false;
}
