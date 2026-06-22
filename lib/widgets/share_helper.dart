// share_helper: metni sistem paylaşım sayfasıyla paylaşır; paylaşım yoksa
// (ör. bazı web ortamları) panoya kopyalamaya düşer.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareText(BuildContext context, String text) async {
  try {
    await SharePlus.instance.share(ShareParams(text: text));
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paylaşım kullanılamıyor; panoya kopyalandı')),
      );
    }
  }
}
