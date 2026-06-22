// feed_page: ana ekran. Dikey PageView ile temalar arasında geçilir (reels
// mantığı). AppBar'da arama, "günün konusu", kategori filtresi ve okuma ayarları.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/filter_provider.dart';
import '../../providers/themes_provider.dart';
import '../../widgets/reading_settings_sheet.dart';
import '../index/theme_index_page.dart';
import 'theme_page.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  final _pageController = PageController();
  final _searchController = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _jumpToFirst() {
    if (_pageController.hasClients) _pageController.jumpToPage(0);
  }

  void _goToTodaysTopic() {
    final list = ref.read(filteredThemesProvider).value ?? const [];
    if (list.isEmpty) return;
    final day = DateTime.now().difference(DateTime(2020, 1, 1)).inDays;
    final index = day % list.length;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Günün konusu: ${list[index].title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _closeSearch() {
    setState(() => _searching = false);
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).set('');
    _jumpToFirst();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = ref.watch(filteredThemesProvider);
    final categories = ref.watch(categoriesProvider);
    final selected = ref.watch(categoryFilterProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Konu ara…',
                  border: InputBorder.none,
                ),
                onChanged: (v) {
                  ref.read(searchQueryProvider.notifier).set(v);
                  _jumpToFirst();
                },
              )
            : const Text('Dört Kitap'),
        actions: _searching
            ? [
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Aramayı kapat',
                  onPressed: _closeSearch,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Konu ara',
                  onPressed: () => setState(() => _searching = true),
                ),
                IconButton(
                  icon: const Icon(Icons.format_list_bulleted),
                  tooltip: 'Tema dizini',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ThemeIndexPage()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.today_outlined),
                  tooltip: 'Günün konusu',
                  onPressed: _goToTodaysTopic,
                ),
                PopupMenuButton<String?>(
                  icon: Icon(selected == null
                      ? Icons.filter_list
                      : Icons.filter_list_alt),
                  tooltip: 'Kategori filtrele',
                  initialValue: selected,
                  onSelected: (value) {
                    ref.read(categoryFilterProvider.notifier).select(value);
                    _jumpToFirst();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String?>(
                      value: null,
                      child: Text('Tüm kategoriler'),
                    ),
                    ...categories.map(
                      (category) => PopupMenuItem<String?>(
                        value: category,
                        child: Text(category),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: 'Okuma ayarları',
                  onPressed: () => showReadingSettings(context),
                ),
              ],
      ),
      body: filtered.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Veri yüklenemedi:\n$error',
                textAlign: TextAlign.center),
          ),
        ),
        data: (themes) {
          if (themes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  query.isNotEmpty
                      ? '“$query” için sonuç bulunamadı.'
                      : selected == null
                          ? 'Henüz tema yok.'
                          : '“$selected” kategorisinde tema bulunamadı.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: themes.length,
            itemBuilder: (context, index) => ThemePage(cluster: themes[index]),
          );
        },
      ),
    );
  }
}
