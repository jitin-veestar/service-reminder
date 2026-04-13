import 'package:flutter/material.dart';

import 'package:service_reminder/core/theme/app_colors.dart';
import 'package:service_reminder/core/theme/app_typography.dart';

/// Mic, animated level bars, pause / resume / stop, re-record and delete clip.
class VoiceNotePanel extends StatelessWidget {
  final bool isLoading;
  final bool isRecording;
  final bool isPaused;
  final bool hasClip;
  final List<double> barLevels;
  final VoidCallback onMic;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onDelete;

  const VoiceNotePanel({
    super.key,
    required this.isLoading,
    required this.isRecording,
    required this.isPaused,
    required this.hasClip,
    required this.barLevels,
    required this.onMic,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(barLevels.length, (i) {
                final h = 6 + barLevels[i] * 46;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 85),
                    width: 5,
                    height: h,
                    decoration: BoxDecoration(
                      color: isRecording && !isPaused
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!hasClip && !isRecording)
                Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  elevation: 2,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: isLoading ? null : onMic,
                    child: const SizedBox(
                      width: 76,
                      height: 76,
                      child: Icon(
                        Icons.mic_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              if (isRecording) ...[
                IconButton(
                  iconSize: 44,
                  tooltip: isPaused ? 'Continue' : 'Pause',
                  onPressed:
                      isLoading ? null : (isPaused ? onResume : onPause),
                  icon: Icon(
                    isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 20),
                IconButton(
                  iconSize: 44,
                  tooltip: 'Stop & save clip',
                  onPressed: isLoading ? null : onStop,
                  icon: Icon(
                    Icons.stop_circle_outlined,
                    color: AppColors.error,
                  ),
                ),
              ],
              if (hasClip && !isRecording) ...[
                IconButton(
                  iconSize: 36,
                  tooltip: 'Remove clip',
                  onPressed: isLoading ? null : onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: isLoading ? null : onMic,
                    child: const SizedBox(
                      width: 52,
                      height: 52,
                      child: Icon(
                        Icons.mic_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (hasClip && !isRecording) ...[
            const SizedBox(height: 10),
            Text(
              'Clip ready — uploads when you save',
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
