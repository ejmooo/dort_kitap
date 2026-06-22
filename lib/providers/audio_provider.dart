// audio_provider: Kuran ayet tilavetini yönetir (Mishary Alafasy, islamic.network
// CDN). Aynı anda tek ayet çalar; UI çalan ayeti ve yükleniyor durumunu yansıtır.
// Çevrimiçi gerektirir.

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AudioState {
  final String? playingKey; // "sure:ayet"
  final bool loading;

  const AudioState({this.playingKey, this.loading = false});
}

class AudioController extends Notifier<AudioState> {
  AudioPlayer? _player;

  @override
  AudioState build() {
    ref.onDispose(() => _player?.dispose());
    return const AudioState();
  }

  AudioPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;
    final player = AudioPlayer();
    player.onPlayerComplete.listen((_) => state = const AudioState());
    _player = player;
    return player;
  }

  String _url(int globalAyah) =>
      'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$globalAyah.mp3';

  Future<void> toggle(String key, int globalAyah) async {
    final player = _ensurePlayer();
    if (state.playingKey == key) {
      await player.stop();
      state = const AudioState();
      return;
    }
    state = AudioState(playingKey: key, loading: true);
    try {
      await player.stop();
      await player.play(UrlSource(_url(globalAyah)));
      state = AudioState(playingKey: key);
    } catch (_) {
      state = const AudioState();
    }
  }

  Future<void> stop() async {
    await _player?.stop();
    state = const AudioState();
  }
}

final audioControllerProvider =
    NotifierProvider<AudioController, AudioState>(AudioController.new);
