// reading_settings_sheet: okuma konforu ayarları (yazı boyutu + tema kipi).
// Alt sayfa (bottom sheet) olarak açılır; ayarlar anında ve kalıcı uygulanır.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

Future<void> showReadingSettings(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _ReadingSettingsSheet(),
  );
}

class _ReadingSettingsSheet extends ConsumerWidget {
  const _ReadingSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final percent = (settings.textScale * 100).round();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Okuma ayarları',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),

            // Yazı boyutu
            Text('Yazı boyutu',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(height: 8),
            Row(
              children: [
                _RoundButton(
                  icon: Icons.text_decrease,
                  onTap: settings.textScale <= SettingsNotifier.minScale
                      ? null
                      : notifier.decreaseText,
                ),
                Expanded(
                  child: Slider(
                    value: settings.textScale,
                    min: SettingsNotifier.minScale,
                    max: SettingsNotifier.maxScale,
                    divisions: 15,
                    label: '%$percent',
                    onChanged: notifier.setTextScale,
                  ),
                ),
                _RoundButton(
                  icon: Icons.text_increase,
                  onTap: settings.textScale >= SettingsNotifier.maxScale
                      ? null
                      : notifier.increaseText,
                ),
              ],
            ),
            Center(
              child: Text('Örnek metin · %$percent',
                  style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 24),

            // Tema kipi
            Text('Görünüm',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto),
                    label: Text('Sistem')),
                ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode),
                    label: Text('Açık')),
                ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode),
                    label: Text('Koyu')),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => notifier.setThemeMode(s.first),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onTap,
      icon: Icon(icon),
    );
  }
}
