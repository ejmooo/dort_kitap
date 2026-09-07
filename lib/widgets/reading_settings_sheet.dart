// reading_settings_sheet: okuma konforu ayarları (yazı boyutu + tema kipi).
// Alt sayfa (bottom sheet) olarak açılır; ayarlar anında ve kalıcı uygulanır.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications.dart';
import '../providers/reminder_provider.dart';
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

            // Günlük hatırlatıcı — web'de yerel bildirim planlanamıyor.
            if (DailyReminders.instance.supported) ...[
              const SizedBox(height: 24),
              Text('Günlük hatırlatıcı',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.primary)),
              const SizedBox(height: 4),
              const _ReminderControls(),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReminderControls extends ConsumerWidget {
  const _ReminderControls();

  Future<void> _toggle(BuildContext context, WidgetRef ref, bool value) async {
    final ok = await ref.read(reminderProvider.notifier).setEnabled(value);
    if (!ok && value && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Bildirim izni verilmedi. Sistem ayarlarından açabilirsin.'),
        ),
      );
    }
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final current = ref.read(reminderProvider);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: 'Hatırlatma saati',
    );
    if (picked != null) {
      await ref.read(reminderProvider.notifier).setTime(picked.hour, picked.minute);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reminder = ref.watch(reminderProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: reminder.enabled,
          onChanged: (v) => _toggle(context, ref, v),
          title: const Text('Günün konusunu hatırlat'),
          subtitle: Text(
            reminder.enabled
                ? 'Her gün ${reminder.label}'
                : 'Kapalı',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        if (reminder.enabled)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _pickTime(context, ref),
              icon: const Icon(Icons.schedule),
              label: Text('Saati değiştir (${reminder.label})'),
            ),
          ),
      ],
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
