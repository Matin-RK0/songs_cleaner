import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Theme;

import '../theme/app_colors.dart';
import '../theme/appearance_theme.dart';
import '../settings/photo_framing.dart';
import 'appearance_photo.dart';

/// Kept outside the route stack so scrolling and navigation share one image.
class AppearanceBackdrop extends StatelessWidget {
  const AppearanceBackdrop({
    super.key,
    required this.path,
    required this.dimming,
    this.framing = const PhotoFraming(),
  });

  final String path;
  final double dimming;
  final PhotoFraming framing;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return RepaintBoundary(
      child: ExcludeSemantics(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: context.colors.background),
            AppearancePhotoSource(
              path: path,
              builder: (_, image, _) => image == null
                  ? const SizedBox.shrink()
                  : FramedAppearancePhoto(image: image, framing: framing),
            ),
            ColoredBox(
              color: AppearanceTheme.photoTint(brightness)
                  .withValues(alpha: dimming),
            ),
          ],
        ),
      ),
    );
  }
}
