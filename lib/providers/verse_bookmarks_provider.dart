// verse_bookmarks_provider: kaydedilen ayetleri ve kişisel notları yönetir.
// shared_preferences içinde JSON olarak kalıcıdır.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_verse.dart';

class VerseBookmarksNotifier extends Notifier<Map<String, SavedVerse>> {
  static const _key = 'saved_verses';
  SharedPreferences? _prefs;

  @override
  Map<String, SavedVerse> build() {
    _load();
    return const {};
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw == null) return;
    final decoded = json.decode(raw);
    if (decoded is! List) return;
    final map = <String, SavedVerse>{};
    for (final item in decoded) {
      if (item is Map<String, dynamic>) {
        final verse = SavedVerse.fromJson(item);
        map[verse.id] = verse;
      }
    }
    state = map;
  }

  Future<void> _persist() async {
    _prefs ??= await SharedPreferences.getInstance();
    final list = state.values.map((v) => v.toJson()).toList();
    await _prefs!.setString(_key, json.encode(list));
  }

  bool contains(String id) => state.containsKey(id);

  Future<void> save(SavedVerse verse) async {
    state = {...state, verse.id: verse};
    await _persist();
  }

  Future<void> remove(String id) async {
    final next = {...state}..remove(id);
    state = next;
    await _persist();
  }

  Future<void> toggle(SavedVerse verse) async {
    if (contains(verse.id)) {
      await remove(verse.id);
    } else {
      await save(verse);
    }
  }

  Future<void> setNote(String id, String note) async {
    final existing = state[id];
    if (existing == null) return;
    state = {...state, id: existing.copyWith(note: note)};
    await _persist();
  }
}

final verseBookmarksProvider =
    NotifierProvider<VerseBookmarksNotifier, Map<String, SavedVerse>>(
        VerseBookmarksNotifier.new);
