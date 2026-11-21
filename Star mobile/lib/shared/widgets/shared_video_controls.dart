import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/tappable/star_gesture_detector.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/widgets/volume_popout_control.dart';

class SharedVideoControls extends StatelessWidget {
  const SharedVideoControls({
    required this.isPlaying,
    required this.showControls,
    required this.volume,
    required this.playbackRate,
    required this.progress,
    required this.onShowControls,
    required this.onTogglePlayPause,
    required this.onVolumeChanged,
    required this.onCyclePlaybackRate,
    required this.onToggleFullscreen,
    required this.onSeekFromGlobalDx,
    super.key,
  });

  final bool isPlaying;
  final bool showControls;
  final double volume;
  final double playbackRate;
  final double progress;
  final VoidCallback onShowControls;
  final Future<void> Function() onTogglePlayPause;
  final Future<void> Function(double value) onVolumeChanged;
  final Future<void> Function() onCyclePlaybackRate;
  final Future<void> Function() onToggleFullscreen;
  final Future<void> Function(double globalDx, BuildContext context)
  onSeekFromGlobalDx;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final StarLocalizations l10n = StarLocalizations.of(context);
    return MouseRegion(
      onHover: (_) => onShowControls(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: StarGestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onShowControls,
            ),
          ),
          AnimatedOpacity(
            opacity: showControls ? 1 : 0,
            duration: const Duration(milliseconds: 140),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Builder(
                    builder: (BuildContext sliderContext) {
                      return StarGestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (TapDownDetails details) =>
                            onSeekFromGlobalDx(
                              details.globalPosition.dx,
                              sliderContext,
                            ),
                        onHorizontalDragUpdate: (DragUpdateDetails details) =>
                            onSeekFromGlobalDx(
                              details.globalPosition.dx,
                              sliderContext,
                            ),
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.24,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              context.colors.brandPrimary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Container(
                    color: Colors.black.withValues(alpha: 0.8),
                    padding: const EdgeInsets.fromLTRB(0, 6, 0, 4),
                    child: Row(
                      children: [
                        IconButton(
                          constraints: const BoxConstraints.tightFor(
                            width: 28,
                            height: 28,
                          ),
                          padding: EdgeInsets.zero,
                          tooltip: isPlaying
                              ? l10n.videoPlayerPause
                              : l10n.videoPlayerPlay,
                          onPressed: onTogglePlayPause,
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: colors.textOnBrandPrimary,
                            size: 18,
                          ),
                        ),
                        VolumePopoutControl(
                          volume: volume,
                          isMuted: false,
                          onVolumeChanged: onVolumeChanged,
                        ),
                        const Spacer(),
                        Semantics(
                          label: l10n.videoPlayerPlaybackSpeed(
                            playbackRate.toString(),
                          ),
                          excludeSemantics: true,
                          button: true,
                          onTap: onCyclePlaybackRate,
                          child: TextButton(
                            onPressed: onCyclePlaybackRate,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(36, 28),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                            ),
                            child: Text(
                              '${playbackRate}x',
                              style: context.textStyles.smallText.copyWith(
                                color: colors.textOnBrandPrimary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          constraints: const BoxConstraints.tightFor(
                            width: 28,
                            height: 28,
                          ),
                          padding: EdgeInsets.zero,
                          tooltip: l10n.videoPlayerFullScreen,
                          onPressed: onToggleFullscreen,
                          icon: Icon(
                            Icons.fullscreen_rounded,
                            color: colors.textOnBrandPrimary,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
