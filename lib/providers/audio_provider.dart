// audio_provider: Kuran ayet tilavetini yönetir (Mishary Alafasy, everyayah.com —
// CORS başlığı döndürdüğü için web'de de çalışır). Bir kuyruk (sûrenin ayetleri)
// üzerinden kesintisiz çalar; ayet bitince otomatik sonrakine geçer. UI çalan
// ayeti, yükleniyor durumunu ve kuyruk (kesintisiz) modunu yansıtır. Çevrimiçi gerektirir.

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kuyruğa alınan tek bir ayet.
class AyahRef {
  final String key; // "sure:ayet"
  final int surah;
  final int ayah;

  const AyahRef({required this.key, required this.surah, required this.ayah});
}

class AudioState {
  final String? playingKey; // "sure:ayet"
  final bool loading;
  final bool continuous; // kuyrukta birden çok ayet varsa (kesintisiz mod)
  final String? error;

  const AudioState({
    this.playingKey,
    this.loading = false,
    this.continuous = false,
    this.error,
  });
}

class AudioController extends Notifier<AudioState> {
  AudioPlayer? _player;
  List<AyahRef> _queue = const [];
  int _index = -1;

  @override
  AudioState build() {
    ref.onDispose(() => _player?.dispose());
    return const AudioState();
  }

  AudioPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;
    final player = AudioPlayer();
    // Ayet bitince otomatik sonraki ayete geç.
    player.onPlayerComplete.listen((_) => _advance());
    _player = player;
    return player;
  }

  // everyayah.com biçimi: SSSAAA (3 hane sûre + 3 hane ayet).
  String _url(int surah, int ayah) {
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/Alafasy_128kbps/$s$a.mp3';
  }

  Future<void> _playAt(int index) async {
    if (index < 0 || index >= _queue.length) {
      await stop();
      return;
    }
    _index = index;
    final entry = _queue[index];
    final continuous = _queue.length > 1;
    state = AudioState(
        playingKey: entry.key, loading: true, continuous: continuous);
    final player = _ensurePlayer();
    try {
      await player.stop();
      await player.play(UrlSource(_url(entry.surah, entry.ayah)));
      state = AudioState(playingKey: entry.key, continuous: continuous);
    } catch (_) {
      _queue = const [];
      _index = -1;
      state = const AudioState(
        error: 'Ses çalınamadı. İnternet bağlantınızı kontrol edin.',
      );
    }
  }

  void _advance() {
    if (_index >= 0 && _index + 1 < _queue.length) {
      _playAt(_index + 1);
    } else {
      _queue = const [];
      _index = -1;
      state = const AudioState();
    }
  }

  /// [queue]'daki [startIndex] ayetinden itibaren kesintisiz çalar. Çalan ayete
  /// tekrar basılırsa durur (aç/kapa).
  Future<void> play(List<AyahRef> queue, int startIndex) async {
    if (startIndex >= 0 &&
        startIndex < queue.length &&
        state.playingKey == queue[startIndex].key) {
      await stop();
      return;
    }
    _queue = queue;
    await _playAt(startIndex);
  }

  /// Tek bir ayeti çalar/durdurur (kuyruk yok).
  Future<void> toggle(String key, int surah, int ayah) =>
      play([AyahRef(key: key, surah: surah, ayah: ayah)], 0);

  Future<void> stop() async {
    _queue = const [];
    _index = -1;
    await _player?.stop();
    state = const AudioState();
  }
}

final audioControllerProvider =
    NotifierProvider<AudioController, AudioState>(AudioController.new);
