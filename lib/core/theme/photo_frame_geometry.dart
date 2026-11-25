import 'dart:math' as math;
import 'dart:ui';

import '../settings/photo_framing.dart';

/// The preview and the app both crop with a single, uniform scale.
abstract final class PhotoFrameGeometry {
  static Rect crop(Size image, Size viewport, PhotoFraming framing) {
    final visible = _visibleSize(image, viewport, framing.zoom);
    return Rect.fromLTWH(
      (framing.x * image.width - visible.width / 2).clamp(
        0,
        image.width - visible.width,
      ),
      (framing.y * image.height - visible.height / 2).clamp(
        0,
        image.height - visible.height,
      ),
      visible.width,
      visible.height,
    );
  }

  static Offset sourcePoint(Rect crop, Size viewport, Offset point) => Offset(
    crop.left + point.dx / viewport.width * crop.width,
    crop.top + point.dy / viewport.height * crop.height,
  );

  /// Keep the same source pixel under the fingers while moving or pinching.
  static PhotoFraming move({
    required Size image,
    required Size viewport,
    required Offset anchor,
    required Offset point,
    required double zoom,
  }) {
    final boundedZoom = zoom.clamp(PhotoFraming.minZoom, PhotoFraming.maxZoom);
    final visible = _visibleSize(image, viewport, boundedZoom);
    final left = (anchor.dx - point.dx / viewport.width * visible.width).clamp(
      0,
      image.width - visible.width,
    );
    final top = (anchor.dy - point.dy / viewport.height * visible.height).clamp(
      0,
      image.height - visible.height,
    );
    return PhotoFraming(
      x: (left + visible.width / 2) / image.width,
      y: (top + visible.height / 2) / image.height,
      zoom: boundedZoom,
    );
  }

  static Size _visibleSize(Size image, Size viewport, double zoom) {
    final scale =
        math.max(viewport.width / image.width, viewport.height / image.height) *
        zoom;
    return Size(
      math.min(image.width, viewport.width / scale),
      math.min(image.height, viewport.height / scale),
    );
  }
}
