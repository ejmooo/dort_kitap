import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/daily_topic.dart';
import '../../providers/filter_provider.dart';
import '../../providers/themes_provider.dart';
import '../../widgets/atlas_motion.dart';
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
  int _current = 0;
  bool _searching = false;

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _resetPosition() {
    _current = 0;
    if (_pageController.hasClients) _pageController.jumpToPage(0);
  }

  void _selectCategory(String? category) {
    AtlasMotion.selection();
    _resetPosition();
    ref.read(categoryFilterProvider.notifier).select(category);
  }

  void _goToTodaysTopic() {
    final list = ref.read(filteredThemesProvider).value ?? const [];
    if (list.isEmpty || !_pageController.hasClients) return;
    AtlasMotion.selection();
    final index = dailyTopicIndex(DateTime.now(), list.length);
    // Avoid constructing every intermediate page in a long collection.
    _pageController.jumpToPage(index);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Günün konusu: ${list[index].title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCategories() {
    final categories = ref.read(categoriesProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .55,
        minChildSize: .3,
        maxChildSize: .85,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Text(
              'Neyi keşfetmek istersin?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Bir konu seç, dört farklı bakış açısına uzan.'),
            const SizedBox(height: 16),
            for (final category in <String?>[null, ...categories])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(category ?? 'Tüm kategoriler'),
                trailing: ref.read(categoryFilterProvider) == category
                    ? const Icon(Icons.check_circle)
                    : const Icon(Icons.arrow_outward, size: 20),
                onTap: () {
                  _selectCategory(category);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = ref.watch(filteredThemesProvider);
    final selected = ref.watch(categoryFilterProvider);
    final query = ref.watch(searchQueryProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48 + MediaQuery.textScalerOf(context).scale(20),
        titleSpacing: 24,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OKUMA ATLASI', style: AppTheme.kicker(context)),
            const Text('Dört Kitap'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Konu ara',
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() => _searching = !_searching);
              if (!_searching) {
                _searchController.clear();
                _resetPosition();
                ref.read(searchQueryProvider.notifier).set('');
              }
            },
          ),
          IconButton(
            tooltip: 'Okuma ayarları',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => showReadingSettings(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          AnimatedSwitcher(
            duration: AtlasMotion.duration(context),
            child: _searching
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Konu, kavram veya kelime ara…',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        _resetPosition();
                        ref.read(searchQueryProvider.notifier).set(value);
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _ExploreChip(
                  label: selected ?? 'Tüm konular',
                  icon: Icons.tune_rounded,
                  selected: true,
                  onTap: _showCategories,
                ),
                const SizedBox(width: 8),
                _ExploreChip(
                  label: 'Günün konusu',
                  icon: Icons.wb_sunny_outlined,
                  onTap: _goToTodaysTopic,
                ),
                const SizedBox(width: 8),
                _ExploreChip(
                  label: 'Tema dizini',
                  icon: Icons.grid_view_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ThemeIndexPage()),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Veri yüklenemedi:\n$error',
                  textAlign: TextAlign.center,
                ),
              ),
              data: (themes) {
                if (themes.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            query.isNotEmpty
                                ? '“$query” için sonuç bulunamadı.'
                                : 'Bu kategoride henüz tema yok.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchQueryProvider.notifier).set('');
                              _selectCategory(null);
                            },
                            child: const Text('Tüm konulara dön'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        scrollDirection: Axis.vertical,
                        itemCount: themes.length,
                        onPageChanged: (index) {
                          AtlasMotion.selection();
                          setState(() => _current = index);
                        },
                        itemBuilder: (context, index) => ThemePage(
                          key: ValueKey(themes[index].id),
                          cluster: themes[index],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'KEŞİF  ${(_current + 1).clamp(1, themes.length).toString().padLeft(2, '0')} / ${themes.length}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                letterSpacing: 1.2,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          IconButton(
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            tooltip: 'Önceki konu',
                            onPressed: _current > 0
                                ? () => AtlasMotion.goToPage(
                                    context,
                                    _pageController,
                                    _current - 1,
                                  )
                                : null,
                            icon: const Icon(
                              Icons.arrow_upward_rounded,
                              size: 18,
                            ),
                          ),
                          IconButton(
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            tooltip: 'Sonraki konu',
                            onPressed: _current < themes.length - 1
                                ? () => AtlasMotion.goToPage(
                                    context,
                                    _pageController,
                                    _current + 1,
                                  )
                                : null,
                            icon: const Icon(
                              Icons.arrow_downward_rounded,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreChip extends StatelessWidget {
  const _ExploreChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: ActionChip(
        avatar: Icon(
          icon,
          size: 17,
          color: selected ? colors.onPrimary : colors.onSurfaceVariant,
        ),
        label: Text(label),
        labelStyle: TextStyle(
          color: selected ? colors.onPrimary : colors.onSurface,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: selected ? colors.primary : colors.surfaceContainerLow,
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
        ),
        shape: const StadiumBorder(),
        onPressed: onTap,
      ),
    );
  }
}
