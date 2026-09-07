// presentation_page: sınıf/projeksiyon için tam ekran, büyük puntolu sunum modu.
// Yatay kaydırma veya ok tuşları (← →) ile temalar arasında geçilir; Esc ile çıkılır.
// Açılınca sistem çubukları gizlenir (immersive), çıkınca geri gelir.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../models/theme_cluster.dart';
import '../../models/verse_entry.dart';
import '../../widgets/book_badge.dart';
import '../../widgets/similarity_chip.dart';
import '../feed/theme_page.dart' show kBookOrder;

class PresentationPage extends StatefulWidget {
  final List<ThemeCluster> themes;
  final int startIndex;

  const PresentationPage({
    super.key,
    required this.themes,
    this.startIndex = 0,
  });

  @override
  State<PresentationPage> createState() => _PresentationPageState();
}

class _PresentationPageState extends State<PresentationPage> {
  late final PageController _controller =
      PageController(initialPage: widget.startIndex);
  late int _index = widget.startIndex;

  @override
  void initState() {
    super.initState();
    // Projeksiyon için sistem çubuklarını gizle.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    super.dispose();
  }

  void _go(int i) {
    if (i < 0 || i >= widget.themes.length) return;
    _controller.animateToPage(
      i,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.pageDown) {
      _go(_index + 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.pageUp) {
      _go(_index - 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.themes.length;
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${_index + 1} / $total'),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Sunumdan çık (Esc)',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        body: PageView.builder(
          controller: _controller,
          onPageChanged: (i) => setState(() => _index = i),
          itemCount: total,
          itemBuilder: (context, i) => _Slide(cluster: widget.themes[i]),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _index > 0 ? () => _go(_index - 1) : null,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Önceki'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _index < total - 1 ? () => _go(_index + 1) : null,
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Sonraki'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final ThemeCluster cluster;

  const _Slide({required this.cluster});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(cluster.category,
                style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 18),
          Text(cluster.title,
              style: theme.textTheme.displaySmall
                  ?.copyWith(fontWeight: FontWeight.w800, height: 1.15)),
          const SizedBox(height: 16),
          SimilarityChip(similarity: cluster.similarity),
          const SizedBox(height: 18),
          Text(cluster.summary,
              style: theme.textTheme.headlineSmall?.copyWith(
                  height: 1.5, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 28),
          for (final book in kBookOrder) ...[
            _BookBlock(book: book, entry: cluster.entryFor(book)),
            const SizedBox(height: 22),
          ],
        ],
      ),
    );
  }
}

class _BookBlock extends StatelessWidget {
  final String book;
  final VerseEntry? entry;

  const _BookBlock({required this.book, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = BookPalette.accent(book);
    final e = entry;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BookBadge(book: book, large: true),
              const Spacer(),
              if (e != null)
                Flexible(
                  child: Text(e.reference,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: accent, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (e == null)
            Text('Bu konuda doğrudan karşılık bulunmadı.',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55)))
          else
            ..._texts(context, e, accent),
        ],
      ),
    );
  }

  List<Widget> _texts(BuildContext context, VerseEntry e, Color accent) {
    final theme = Theme.of(context);
    final widgets = <Widget>[];
    if (e.hasArabic) {
      widgets.add(Directionality(
        textDirection: TextDirection.rtl,
        child: Text(e.textAr!,
            textAlign: TextAlign.right,
            style: AppTheme.arabic(context, fontSize: 34)),
      ));
    }
    if (e.hasTurkish) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 16));
      widgets.add(Text(e.text,
          style: theme.textTheme.headlineSmall?.copyWith(height: 1.55)));
    } else if (e.hasEnglish) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 16));
      widgets.add(Text(e.textEn!,
          style: theme.textTheme.headlineSmall
              ?.copyWith(height: 1.55, fontStyle: FontStyle.italic)));
    }
    return widgets;
  }
}
