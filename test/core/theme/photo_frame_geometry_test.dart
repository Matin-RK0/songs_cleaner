import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/core/settings/photo_framing.dart';
import 'package:songs_cleaner/core/theme/photo_frame_geometry.dart';

void main() {
  const portrait = Size(360, 800);
  const landscape = Size(1600, 900);
  const tall = Size(720, 1600);

  test('every source and viewport combination preserves aspect and has no blank area', () {
    for (final source in [landscape, tall]) {
      for (final viewport in [portrait, landscape]) {
        final crop = PhotoFrameGeometry.crop(
          source,
          viewport,
          const PhotoFraming(x: 1, y: 0, zoom: 2),
        );
        expect(crop.size.aspectRatio, closeTo(viewport.aspectRatio, 0.000001));
        expect(crop.left, greaterThanOrEqualTo(0));
        expect(crop.top, 0);
        expect(crop.right, closeTo(source.width, 0.000001));
        expect(crop.bottom, lessThanOrEqualTo(source.height));
      }
    }
  });

  test('zoom and movement preserve the pixel under the fingers', () {
    final crop = PhotoFrameGeometry.crop(
      landscape,
      portrait,
      const PhotoFraming(),
    );
    final anchor = PhotoFrameGeometry.sourcePoint(
      crop,
      portrait,
      const Offset(160, 350),
    );
    const point = Offset(240, 450);
    final framing = PhotoFrameGeometry.move(
      image: landscape,
      viewport: portrait,
      anchor: anchor,
      point: point,
      zoom: 2,
    );
    final moved = PhotoFrameGeometry.crop(landscape, portrait, framing);
    final pixel = PhotoFrameGeometry.sourcePoint(moved, portrait, point);
    expect((pixel - anchor).distance, closeTo(0, 0.000001));
  });
}
