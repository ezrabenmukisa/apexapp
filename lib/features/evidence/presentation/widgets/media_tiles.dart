import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/hatched_box.dart';
import '../../domain/entities/evidence.dart';

/// A site photo/video tile. Real URLs and local files render as images;
/// simulated media (`mock://…`, no file) show a labelled placeholder.
class MediaTile extends StatelessWidget {
  const MediaTile({
    super.key,
    this.url,
    this.localPath,
    this.label,
    this.isVideo = false,
    this.duration,
    this.overlayText,
    this.onTap,
  });

  factory MediaTile.fromUrl(
    String url, {
    VoidCallback? onTap,
    String? overlayText,
  }) => MediaTile(
    url: url,
    label: _labelFromUrl(url),
    isVideo: Evidence.isVideoUrl(url),
    overlayText: overlayText,
    onTap: onTap,
  );

  factory MediaTile.fromCapture(CapturedMedia m, {VoidCallback? onTap}) =>
      MediaTile(
        localPath: m.localPath,
        label: m.label,
        isVideo: m.kind == MediaKind.video,
        duration: m.durationSeconds,
        onTap: onTap,
      );

  final String? url;
  final String? localPath;
  final String? label;
  final bool isVideo;
  final int? duration;

  /// Large centred text, e.g. "+3".
  final String? overlayText;
  final VoidCallback? onTap;

  static String _labelFromUrl(String url) {
    final last = Uri.tryParse(url)?.pathSegments.lastOrNull ?? url;
    return last
        .replaceAll(RegExp(r'\.(jpg|jpeg|png|mp4|mov)$'), '')
        .replaceFirst('video-', '')
        .replaceAll('-', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final u = url;
    final path = localPath;
    Widget image;
    if (u != null && u.startsWith('http') && !isVideo) {
      image = Image.network(u, fit: BoxFit.cover);
    } else if (path != null && !isVideo) {
      image = Image.file(File(path), fit: BoxFit.cover);
    } else {
      image = HatchedBox(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              overlayText == null && label != null ? '[$label]' : '',
              textAlign: TextAlign.center,
              style: AppTextStyles.small.copyWith(
                color: AppColors.ink2,
                fontSize: 11,
              ),
            ),
          ),
        ),
      );
    }
    return Semantics(
      label: '${isVideo ? 'Video' : 'Photo'}${label == null ? '' : ': $label'}',
      button: onTap != null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                image,
                if (isVideo)
                  const Center(
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.ink,
                      child: Icon(
                        Icons.play_arrow,
                        color: AppColors.surface,
                        size: 22,
                      ),
                    ),
                  ),
                if (isVideo && duration != null)
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      color: AppColors.ink,
                      child: Text(
                        '0:${duration.toString().padLeft(2, '0')}',
                        style: AppTextStyles.mono(
                          size: 10,
                          color: AppColors.surface,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                if (overlayText != null)
                  ColoredBox(
                    color: AppColors.sunk.withValues(alpha: 0.85),
                    child: Center(
                      child: Text(overlayText!, style: AppTextStyles.title),
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

/// Receipt chip: PDF badge or image icon, with the file name.
class ReceiptChip extends StatelessWidget {
  const ReceiptChip({super.key, required this.name, this.onTap, this.onRemove});

  final String name;

  /// Opens the receipt in the in-app viewer.
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  bool get _isPdf => name.toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: onTap == null ? null : 'Open receipt $name',
    child: Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.controlBorder),
        borderRadius: BorderRadius.circular(AppDimensions.radiusControl),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: _content()),
    ),
  );

  Widget _content() => Container(
    padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
    constraints: const BoxConstraints(minHeight: 40),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          color: _isPdf ? AppColors.flaggedBg : AppColors.sunk,
          child: Text(
            _isPdf ? 'PDF' : 'IMG',
            style: AppTextStyles.mono(
              size: 10,
              color: _isPdf ? AppColors.flagged : AppColors.ink2,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption,
          ),
        ),
        if (onRemove != null)
          IconButton(
            tooltip: 'Remove $name',
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 16),
          )
        else
          const SizedBox(width: 4),
      ],
    ),
  );
}
