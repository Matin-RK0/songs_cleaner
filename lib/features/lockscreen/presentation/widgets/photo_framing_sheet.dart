import 'package:material_ui/material_ui.dart';

import '../../../../core/extensions/context_l10n.dart';
import '../../../../core/settings/photo_framing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/photo_frame_geometry.dart';
import '../../../../core/widgets/appearance_photo.dart';

Future<PhotoFraming?> showPhotoFramingSheet(
  BuildContext context,
  String path, {
  PhotoFraming initial = const PhotoFraming(),
}) {
  final viewport = MediaQuery.sizeOf(context);
  return showModalBottomSheet<PhotoFraming>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    // Vertical drags belong to the photo, not to the sheet dismissal gesture.
    enableDrag: false,
    backgroundColor: context.colors.surfaceHigh,
    builder: (_) => FractionallySizedBox(
      heightFactor: AppSpacing.sheetHeightFactor,
      child: _PhotoFramingSheet(
        path: path,
        aspectRatio: viewport.aspectRatio,
        initial: initial,
      ),
    ),
  );
}

class _PhotoFramingSheet extends StatefulWidget {
  const _PhotoFramingSheet({
    required this.path,
    required this.aspectRatio,
    required this.initial,
  });

  final String path;
  final double aspectRatio;
  final PhotoFraming initial;

  @override
  State<_PhotoFramingSheet> createState() => _PhotoFramingSheetState();
}

class _PhotoFramingSheetState extends State<_PhotoFramingSheet> {
  late PhotoFraming _framing = widget.initial;
  Offset? _anchor;
  double _initialZoom = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppearancePhotoSource(
      path: widget.path,
      builder: (context, image, failed) => SafeArea(
        top: false,
        child: Padding(
          padding: AppSpacing.allMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.photoFramingTitle, style: AppTypography.sheetTitle),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.photoFramingInstructions),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: Center(
                  child: image == null
                      ? (failed
                            ? Text(
                                l10n.photoFramingLoadFailed,
                                textAlign: TextAlign.center,
                              )
                            : const CircularProgressIndicator())
                      : AspectRatio(
                          aspectRatio: widget.aspectRatio,
                          child: ClipRRect(
                            borderRadius: AppRadius.md,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final viewport = constraints.biggest;
                                final size = Size(
                                  image.width.toDouble(),
                                  image.height.toDouble(),
                                );
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onScaleStart: (details) {
                                    if (viewport.isEmpty) return;
                                    final crop = PhotoFrameGeometry.crop(
                                      size,
                                      viewport,
                                      _framing,
                                    );
                                    _anchor = PhotoFrameGeometry.sourcePoint(
                                      crop,
                                      viewport,
                                      details.localFocalPoint,
                                    );
                                    _initialZoom = _framing.zoom;
                                  },
                                  onScaleUpdate: (details) {
                                    final anchor = _anchor;
                                    if (anchor == null || viewport.isEmpty) {
                                      return;
                                    }
                                    setState(
                                      () => _framing = PhotoFrameGeometry.move(
                                        image: size,
                                        viewport: viewport,
                                        anchor: anchor,
                                        point: details.localFocalPoint,
                                        zoom: _initialZoom * details.scale,
                                      ),
                                    );
                                  },
                                  onScaleEnd: (_) => _anchor = null,
                                  child: RepaintBoundary(
                                    child: FramedAppearancePhoto(
                                      image: image,
                                      framing: _framing,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                ),
              ),
              Row(
                children: [
                  Text(l10n.photoFramingZoom),
                  Expanded(
                    child: Slider(
                      min: PhotoFraming.minZoom,
                      max: PhotoFraming.maxZoom,
                      value: _framing.zoom,
                      onChanged: image == null
                          ? null
                          : (zoom) => setState(
                              () => _framing = PhotoFraming(
                                x: _framing.x,
                                y: _framing.y,
                                zoom: zoom,
                              ),
                            ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.appearanceDefault,
                    onPressed: image == null
                        ? null
                        : () => setState(() => _framing = const PhotoFraming()),
                    icon: const Icon(Icons.restart_alt_rounded),
                  ),
                ],
              ),
              FilledButton(
                onPressed: image == null
                    ? null
                    : () => Navigator.pop(context, _framing),
                child: Text(l10n.saveAction),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
