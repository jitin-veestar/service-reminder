import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:service_reminder/core/theme/app_colors.dart';
import 'package:service_reminder/core/theme/app_typography.dart';
import 'package:service_reminder/features/services/presentation/providers/voice_playback_provider.dart';

String _formatMmSs(Duration d) {
  if (d.isNegative) return '0:00';
  final totalSeconds = d.inSeconds;
  final m = totalSeconds ~/ 60;
  final s = totalSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// In-card voice note player: play/pause, seek slider, elapsed / duration.
class HistoryVoicePlayerBar extends ConsumerStatefulWidget {
  final String storagePath;

  const HistoryVoicePlayerBar({super.key, required this.storagePath});

  @override
  ConsumerState<HistoryVoicePlayerBar> createState() =>
      _HistoryVoicePlayerBarState();
}

class _HistoryVoicePlayerBarState extends ConsumerState<HistoryVoicePlayerBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voicePlaybackProvider);
    final notifier = ref.read(voicePlaybackProvider.notifier);
    final isThis = state.storagePath == widget.storagePath;
    final loading = isThis && state.loading;
    final duration = state.duration ?? Duration.zero;
    final position = isThis ? state.position : Duration.zero;

    double sliderValue() {
      if (_dragValue != null) return _dragValue!.clamp(0.0, 1.0);
      if (!isThis || duration.inMilliseconds <= 0) return 0;
      return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    }

    final canScrub = isThis && !loading && duration.inMilliseconds > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.mic_rounded,
                size: 20,
                color: AppColors.primary.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Voice note',
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isThis && !loading && state.errorMessage == null) ...[
                Material(
                  color: state.playbackSpeed >= 1.5
                      ? AppColors.primary.withValues(alpha: 0.14)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: notifier.togglePlaybackSpeed,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Text(
                        state.playbackSpeed >= 1.5 ? '2x' : '1x',
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              if (loading)
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton.filledTonal(
                  onPressed: () =>
                      notifier.playOrPause(widget.storagePath),
                  style: IconButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: Icon(
                    isThis && state.playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 28,
                  ),
                ),
            ],
          ),
          if (isThis && state.errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              state.errorMessage!,
              style: AppTypography.caption.copyWith(color: AppColors.error),
            ),
            TextButton(
              onPressed: () => notifier.playOrPause(widget.storagePath),
              child: const Text('Retry'),
            ),
          ] else ...[
            const SizedBox(height: 4),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.border,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.12),
              ),
              child: Slider(
                value: sliderValue(),
                onChanged: canScrub
                    ? (v) => setState(() => _dragValue = v)
                    : null,
                onChangeEnd: canScrub
                    ? (v) {
                        notifier.seek(widget.storagePath, v);
                        setState(() => _dragValue = null);
                      }
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 4, bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatMmSs(position),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    duration.inMilliseconds > 0
                        ? _formatMmSs(duration)
                        : isThis && loading
                            ? '…'
                            : '--:--',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
