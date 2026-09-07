// verse_image_sheet: ayeti görsel kart olarak gösterir ve PNG olarak paylaşır.
// Kart RepaintBoundary içinde çizilir, boundary.toImage ile yakalanır — ek bir
// ekran görüntüsü paketine gerek yok.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../widgets/verse_image_card.dart';

/// Ayet görselini önizleme sayfası olarak açar.
Future<void> showVerseImageSheet(
  BuildContext context, {
  required String text,
  required String reference,
  required String book,
  String? arabic,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => VerseImagePage(
        text: text,
        reference: reference,
        book: book,
        arabic: arabic,
      ),
    ),
  );
}

class VerseImagePage extends StatefulWidget {
  final String text;
  final String reference;
  final String book;
  final String? arabic;

  const VerseImagePage({
    super.key,
    required this.text,
    required this.reference,
    required this.book,
    this.arabic,
  });

  @override
  State<VerseImagePage> createState() => _VerseImagePageState();
}

class _VerseImagePageState extends State<VerseImagePage> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _busy = false;
  bool _withArabic = true;

  Future<Uint8List?> _capture() async {
    final object = _boundaryKey.currentContext?.findRenderObject();
    if (object is! RenderRepaintBoundary) return null;
    // 3x: 360 mantıksal genişlik → 1080 px, sosyal medya için yeterli.
    final image = await object.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) throw StateError('Görsel oluşturulamadı');
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'image/png')],
          // io tarafında XFile.fromData'nın "name" alanı yok sayılır; dosya
          // adını share_plus'a bu şekilde bildiriyoruz.
          fileNameOverrides: ['dort-kitap-ayet.png'],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Görsel paylaşılamadı: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) throw StateError('Görsel oluşturulamadı');
      // Pano görsel desteği platforma bağlı; metin her yerde çalışır.
      await Clipboard.setData(
        ClipboardData(text: '${widget.reference}\n\n${widget.text}'),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ayet metni panoya kopyalandı')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasArabic = (widget.arabic ?? '').isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Görsel olarak paylaş'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Center(
            child: RepaintBoundary(
              key: _boundaryKey,
              child: VerseImageCard(
                text: widget.text,
                reference: widget.reference,
                book: widget.book,
                arabic: _withArabic ? widget.arabic : null,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (hasArabic)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _withArabic,
              onChanged: _busy ? null : (v) => setState(() => _withArabic = v),
              title: const Text('Arapça metni de göster'),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _share,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share),
                  label: const Text('Görseli paylaş'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _copy,
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Metni kopyala'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Görsel her zaman açık kâğıt renginde üretilir; koyu tema '
            'kullansan da paylaştığın kart aynı görünür.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
