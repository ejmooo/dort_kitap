// quran_page: tüm sûrelerin aranabilir listesi. Bir sûreye dokununca ayetleri
// (Arapça + Türkçe meal) ve varsa benzerlikleri gösteren SurahPage açılır.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/parallel.dart';
import '../../models/quran_models.dart';
import '../../providers/quran_provider.dart';
import '../../widgets/reading_settings_sheet.dart';
import 'surah_page.dart';

class QuranPage extends ConsumerStatefulWidget {
  const QuranPage({super.key});

  @override
  ConsumerState<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends ConsumerState<QuranPage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<QuranSurah> _filter(List<QuranSurah> surahs) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return surahs;
    return surahs.where((s) {
      return s.name.toLowerCase().contains(q) || s.number.toString() == q;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final quran = ref.watch(quranProvider);
    final parallels = ref.watch(parallelsProvider).value ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kur’an-ı Kerim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Okuma ayarları',
            onPressed: () => showReadingSettings(context),
          ),
        ],
      ),
      body: quran.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Yüklenemedi: $error')),
        data: (surahs) {
          final list = _filter(surahs);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SearchBar(
                  controller: _controller,
                  hintText: 'Sûre ara (ad veya numara)',
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (_query.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      ),
                  ],
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const Center(child: Text('Sonuç bulunamadı.'))
                    : ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) =>
                            _SurahTile(surah: list[i], parallels: parallels),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  final QuranSurah surah;
  final Map<String, List<Parallel>> parallels;

  const _SurahTile({required this.surah, required this.parallels});

  int get _parallelCount {
    final prefix = '${surah.number}:';
    return parallels.keys.where((k) => k.startsWith(prefix)).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = _parallelCount;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
        foregroundColor: theme.colorScheme.primary,
        child: Text('${surah.number}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      title: Text(surah.name,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${surah.ayahCount} ayet'),
      trailing: count > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count benzerlik',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SurahPage(surah: surah)),
      ),
    );
  }
}
