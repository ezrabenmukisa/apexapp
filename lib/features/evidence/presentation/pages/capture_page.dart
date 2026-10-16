import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/geo.dart';
import '../../../../core/widgets/hatched_box.dart';
import '../bloc/evidence_cubits.dart';
import '../widgets/media_tiles.dart';

/// Site manager 08: in-app camera. No gallery — site media must be taken
/// here so location and time are frozen at the shutter.
///
/// The viewfinder is simulated until the `camera` plugin lands (issue #4).
class CapturePage extends StatelessWidget {
  const CapturePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<CaptureCubit>()..refreshFix(),
    child: const _CaptureView(),
  );
}

class _CaptureView extends StatelessWidget {
  const _CaptureView();

  Future<void> _shutter(BuildContext context) async {
    final media = await context.read<CaptureCubit>().shutter();
    if (media != null && context.mounted) {
      context.read<EvidenceDraftCubit>().addMedia(media);
    }
  }

  @override
  Widget build(BuildContext context) {
    final capture = context.watch<CaptureCubit>().state;
    final draft = context.watch<EvidenceDraftCubit>().state;
    final site = context.watch<SiteCubit>().state.data;
    final milestone = site?.assignment?.current;
    final project = site?.assignment?.project;
    final fix = capture.fix;
    final distance = fix == null || project == null
        ? null
        : distanceInMetres(
            fix.latitude,
            fix.longitude,
            project.latitude,
            project.longitude,
          );
    final isVideo = capture.mode == CaptureMode.video;
    String mmss(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

    return Theme(
      data: Theme.of(context).copyWith(scaffoldBackgroundColor: AppColors.ink),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.close, color: AppColors.surface),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            isVideo ? 'Video walkthrough' : 'Photo',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.surface,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${milestone?.title ?? ''} · ${isVideo ? 'under 1 min' : 'each part of the work'}',
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.rule,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _Viewfinder(
                    fixText: fix == null
                        ? 'LOCATING…'
                        : '${Formatters.coordinates(fix.latitude, fix.longitude).replaceAll(',', ' ·')}'
                              '${distance == null ? '' : ' · ${distance.round()} M FROM PIN'}',
                    onSite: distance != null && distance <= onSiteRadiusMetres,
                    recording: capture.recording,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final mode in CaptureMode.values)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextButton(
                          onPressed: capture.recording
                              ? null
                              : () =>
                                    context.read<CaptureCubit>().setMode(mode),
                          style: TextButton.styleFrom(
                            backgroundColor: capture.mode == mode
                                ? AppColors.surface
                                : Colors.transparent,
                            foregroundColor: capture.mode == mode
                                ? AppColors.ink
                                : AppColors.rule,
                            minimumSize: const Size(72, 44),
                          ),
                          child: Text(
                            mode == CaptureMode.photo ? 'Photo' : 'Video',
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 88,
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _ThumbnailButton(
                            count: draft.media.length,
                            last: draft.media.lastOrNull == null
                                ? null
                                : MediaTile.fromCapture(draft.media.last),
                            onTap: draft.media.isEmpty
                                ? null
                                : () => context.pushReplacement(
                                    AppRoutes.siteSubmit,
                                  ),
                          ),
                        ),
                      ),
                      _ShutterButton(
                        recording: capture.recording,
                        busy: capture.busy,
                        onTap: () => _shutter(context),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: isVideo
                              ? Text(
                                  '${mmss(capture.seconds)} / ${mmss(CaptureCubit.maxVideoSeconds)}',
                                  style: AppTextStyles.mono(
                                    color: AppColors.surface,
                                    size: 13,
                                    letterSpacing: 0,
                                  ),
                                )
                              : TextButton(
                                  onPressed: draft.media.isEmpty
                                      ? null
                                      : () => context.pushReplacement(
                                          AppRoutes.siteSubmit,
                                        ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.surface,
                                  ),
                                  child: const Text('Done'),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Viewfinder extends StatelessWidget {
  const _Viewfinder({
    required this.fixText,
    required this.onSite,
    required this.recording,
  });

  final String fixText;
  final bool onSite;
  final bool recording;

  @override
  Widget build(BuildContext context) => HatchedBox(
    background: const Color(0xFF2E2923),
    stripe: const Color(0x14FFFFFF),
    borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
    child: Stack(
      children: [
        const Positioned.fill(child: CustomPaint(painter: _CornersPainter())),
        Center(
          child: Text(
            '[live camera]',
            style: AppTextStyles.caption.copyWith(color: AppColors.rule),
          ),
        ),
        if (recording)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                color: AppColors.flagged,
                child: Text(
                  '● REC',
                  style: AppTextStyles.mono(color: AppColors.surface, size: 11),
                ),
              ),
            ),
          ),
        Positioned(
          left: 10,
          right: 10,
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    fixText,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.mono(
                      color: AppColors.surface,
                      size: 10.5,
                      letterSpacing: 0.02,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.circle,
                  size: 8,
                  color: onSite ? AppColors.approvedBg : AppColors.changesBg,
                ),
                const SizedBox(width: 4),
                Text(
                  onSite ? 'ON SITE' : 'CHECK',
                  style: AppTextStyles.mono(
                    color: onSite ? AppColors.approvedBg : AppColors.changesBg,
                    size: 10.5,
                    letterSpacing: 0.02,
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

class _CornersPainter extends CustomPainter {
  const _CornersPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 16.0, len = 30.0;
    final p = Paint()
      ..color = const Color(0xFFF6F2EA)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final w = size.width, h = size.height;
    canvas
      ..drawPath(
        Path()
          ..moveTo(inset, inset + len)
          ..lineTo(inset, inset)
          ..lineTo(inset + len, inset),
        p,
      )
      ..drawPath(
        Path()
          ..moveTo(w - inset - len, inset)
          ..lineTo(w - inset, inset)
          ..lineTo(w - inset, inset + len),
        p,
      )
      ..drawPath(
        Path()
          ..moveTo(inset, h - inset - len - 44)
          ..lineTo(inset, h - inset - 44)
          ..lineTo(inset + len, h - inset - 44),
        p,
      )
      ..drawPath(
        Path()
          ..moveTo(w - inset - len, h - inset - 44)
          ..lineTo(w - inset, h - inset - 44)
          ..lineTo(w - inset, h - inset - len - 44),
        p,
      );
  }

  @override
  bool shouldRepaint(_CornersPainter oldDelegate) => false;
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({
    required this.recording,
    required this.busy,
    required this.onTap,
  });

  final bool recording;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: recording ? 'Stop recording' : 'Take',
    excludeSemantics: true,
    child: GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: 80,
        height: 80,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surface, width: 4),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: busy ? AppColors.lateriteDeep : const Color(0xFFC75A2F),
            shape: recording ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: recording ? BorderRadius.circular(8) : null,
          ),
          margin: recording ? const EdgeInsets.all(14) : EdgeInsets.zero,
        ),
      ),
    ),
  );
}

class _ThumbnailButton extends StatelessWidget {
  const _ThumbnailButton({required this.count, this.last, this.onTap});

  final int count;
  final Widget? last;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$count captured. Review and submit.',
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        height: 64,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.surface, width: 1.5),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusControl,
                  ),
                ),
                child: last,
              ),
            ),
            if (count > 0)
              Positioned(
                top: -8,
                right: -8,
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: AppColors.surface,
                  child: Text(
                    '$count',
                    style: AppTextStyles.small.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
