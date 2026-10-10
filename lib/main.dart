// main: uygulamanın giriş noktası. ProviderScope + MaterialApp'i kurar,
// açık/koyu temayı ve kullanıcı yazı boyutunu uygular, ana kabuk olarak
// RootShell'i (alt menülü gezinme) açar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_theme.dart';
import 'features/shell/root_shell.dart';
import 'providers/reminder_provider.dart';
import 'providers/settings_provider.dart';

void main() {
  runApp(const ProviderScope(child: DortKitapApp()));
}

class DortKitapApp extends ConsumerWidget {
  const DortKitapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    // Hatırlatıcılar yalnızca birkaç gün ileriye kurulur; sağlayıcıyı açılışta
    // canlandırmak pencereyi yeniden doldurur.
    ref.watch(reminderProvider);
    return MaterialApp(
      title: 'Dört Kitap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            MediaQuery.textScalerOf(context).scale(1) * settings.textScale,
          ),
        ),
        child: child!,
      ),
      home: const RootShell(),
    );
  }
}
