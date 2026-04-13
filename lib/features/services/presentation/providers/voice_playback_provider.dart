import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'package:service_reminder/core/constants/app_constants.dart';
import 'package:service_reminder/core/services/supabase/supabase_client_provider.dart';

/// Single shared voice player for service history (one clip at a time).
final voicePlaybackProvider =
    StateNotifierProvider<VoicePlaybackNotifier, VoicePlaybackState>((ref) {
  return VoicePlaybackNotifier(ref);
});

class VoicePlaybackState {
  final String? storagePath;
  final bool loading;
  final bool playing;
  final Duration position;
  final Duration? duration;
  final String? errorMessage;
  /// Playback rate (1.0 or 2.0 for voice notes).
  final double playbackSpeed;

  const VoicePlaybackState({
    this.storagePath,
    this.loading = false,
    this.playing = false,
    this.position = Duration.zero,
    this.duration,
    this.errorMessage,
    this.playbackSpeed = 1.0,
  });

  bool get isActive => storagePath != null;

  VoicePlaybackState copyWith({
    String? storagePath,
    bool? loading,
    bool? playing,
    Duration? position,
    Duration? duration,
    String? errorMessage,
    double? playbackSpeed,
    bool clearError = false,
    bool clearPath = false,
  }) {
    return VoicePlaybackState(
      storagePath: clearPath ? null : (storagePath ?? this.storagePath),
      loading: loading ?? this.loading,
      playing: playing ?? this.playing,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    );
  }
}

class VoicePlaybackNotifier extends StateNotifier<VoicePlaybackState> {
  VoicePlaybackNotifier(this.ref) : super(const VoicePlaybackState());

  final Ref ref;
  AudioPlayer? _player;
  final List<StreamSubscription<dynamic>> _subs = [];

  /// After natural completion we seek to 0 and pause; the platform may still
  /// emit `playing: true` briefly — keep UI paused until the user taps play.
  bool _pausedAtEndAwaitingPlay = false;

  Future<void> _disposePlayer() async {
    _pausedAtEndAwaitingPlay = false;
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    await _player?.dispose();
    _player = null;
  }

  Future<String> _signedUrl(String storagePath) async {
    final client = ref.read(supabaseClientProvider);
    return client.storage
        .from(AppConstants.serviceRecordingsBucket)
        .createSignedUrl(storagePath, 3600);
  }

  void _attachSubscriptions() {
    final p = _player;
    if (p == null) return;

    _subs.add(
      p.positionStream.listen((pos) {
        state = state.copyWith(position: pos);
      }),
    );
    _subs.add(
      p.durationStream.listen((d) {
        if (d != null) {
          state = state.copyWith(duration: d);
        }
      }),
    );
    _subs.add(
      p.playerStateStream.listen((ps) {
        if (ps.processingState == ProcessingState.completed) {
          unawaited(_resetToStartAfterComplete(p));
        } else {
          final playing = _pausedAtEndAwaitingPlay ? false : ps.playing;
          state = state.copyWith(playing: playing);
        }
      }),
    );
  }

  /// After natural end: head back to 0:00 and show play (not pause).
  Future<void> _resetToStartAfterComplete(AudioPlayer player) async {
    try {
      await player.seek(Duration.zero);
      await player.pause();
    } catch (_) {}
    if (_player != player) return;
    _pausedAtEndAwaitingPlay = true;
    state = state.copyWith(playing: false, position: Duration.zero);
  }

  /// Play this clip, pause/resume if already loaded, or switch from another clip.
  Future<void> playOrPause(String storagePath) async {
    if (storagePath.isEmpty) return;

    if (state.storagePath == storagePath && _player != null) {
      if (_player!.playing) {
        await _player!.pause();
      } else {
        _pausedAtEndAwaitingPlay = false;
        await _player!.play();
      }
      return;
    }

    state = VoicePlaybackState(
      storagePath: storagePath,
      loading: true,
      playing: false,
      position: Duration.zero,
      duration: null,
      playbackSpeed: 1.0,
    );

    try {
      await _disposePlayer();
      final url = await _signedUrl(storagePath);
      _player = AudioPlayer();
      await _player!.setUrl(url);
      await _player!.setSpeed(1.0);
      _attachSubscriptions();

      final d = _player!.duration;
      state = state.copyWith(
        loading: false,
        duration: d,
        clearError: true,
        playbackSpeed: 1.0,
      );
      await _player!.play();
    } catch (e, st) {
      await _disposePlayer();
      state = VoicePlaybackState(
        storagePath: storagePath,
        loading: false,
        playing: false,
        playbackSpeed: 1.0,
        errorMessage: e.toString(),
      );
      assert(() {
        // ignore: avoid_print
        print('Voice playback: $e\n$st');
        return true;
      }());
    }
  }

  Future<void> seek(String storagePath, double value) async {
    if (state.storagePath != storagePath || _player == null) return;
    final d = state.duration ?? _player!.duration;
    if (d == null || d.inMilliseconds <= 0) return;
    final target = Duration(
      milliseconds: (value.clamp(0.0, 1.0) * d.inMilliseconds).round(),
    );
    _pausedAtEndAwaitingPlay = false;
    await _player!.seek(target);
  }

  /// Toggles between 1x and 2x for the active clip.
  Future<void> togglePlaybackSpeed() async {
    if (_player == null) return;
    final next = state.playbackSpeed >= 1.5 ? 1.0 : 2.0;
    state = state.copyWith(playbackSpeed: next);
    await _player!.setSpeed(next);
  }

  Future<void> stop() async {
    await _disposePlayer();
    state = const VoicePlaybackState();
  }

  @override
  void dispose() {
    unawaited(_disposePlayer());
    super.dispose();
  }
}
