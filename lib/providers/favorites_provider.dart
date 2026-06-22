// favorites_provider: favori tema id'lerini shared_preferences ile kalıcı
// saklayan Notifier (klasik, kod üretimi olmayan Riverpod deseni).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesNotifier extends Notifier<Set<String>> {
  static const String _key = 'favorite_theme_ids';
  SharedPreferences? _prefs;

  @override
  Set<String> build() {
    // Önce boş başla, ardından diskten yükle (asenkron).
    _loadInitial();
    return <String>{};
  }

  Future<void> _loadInitial() async {
    _prefs = await SharedPreferences.getInstance();
    state = (_prefs!.getStringList(_key) ?? const <String>[]).toSet();
  }

  /// Temayı favorilere ekler/çıkarır ve diske yazar.
  Future<void> toggle(String id) async {
    final next = {...state};
    if (!next.remove(id)) next.add(id);
    state = next;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setStringList(_key, next.toList());
  }

  bool isFavorite(String id) => state.contains(id);
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);
