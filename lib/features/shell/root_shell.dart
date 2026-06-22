// root_shell: alt menülü ana gezinme kabuğu (Akış · Kur'an · Favoriler · Hakkında).
// Sekmeler IndexedStack ile durumunu korur. İlk açılışta karşılama ekranı gösterir.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../about/about_page.dart';
import '../favorites/favorites_page.dart';
import '../feed/feed_page.dart';
import '../library/library_page.dart';

class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  int _index = 0;

  static const _pages = [
    FeedPage(),
    LibraryPage(),
    FavoritesPage(),
    AboutPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowIntro());
  }

  Future<void> _maybeShowIntro() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('seen_intro') ?? false) return;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _WelcomeDialog(),
    );
    await prefs.setBool('seen_intro', true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dynamic_feed_outlined),
              selectedIcon: Icon(Icons.dynamic_feed),
              label: 'Akış'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Oku'),
          NavigationDestination(
              icon: Icon(Icons.bookmark_outline),
              selectedIcon: Icon(Icons.bookmark),
              label: 'Favoriler'),
          NavigationDestination(
              icon: Icon(Icons.info_outline),
              selectedIcon: Icon(Icons.info),
              label: 'Hakkında'),
        ],
      ),
    );
  }
}

class _WelcomeDialog extends StatelessWidget {
  const _WelcomeDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Dört Kitap’a hoş geldiniz'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dört kutsal kitabın ortak konuları nasıl ele aldığını tarafsız '
            'biçimde keşfedin.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          const _Tip(icon: Icons.swipe_vertical, text: 'Yukarı/aşağı kaydır: konu değiştir'),
          const _Tip(icon: Icons.swipe, text: 'Sağa/sola kaydır: kitap değiştir'),
          const _Tip(icon: Icons.menu_book, text: 'Oku sekmesi: tüm Kur’an ve Kitab-ı Mukaddes'),
          const _Tip(icon: Icons.bookmark_add, text: 'Ayet menüsü (⋮): kaydet ve not ekle'),
          const _Tip(icon: Icons.tune, text: 'Yazı boyutu ve tema: okuma ayarlarından'),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Başla'),
        ),
      ],
    );
  }
}

class _Tip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Tip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
