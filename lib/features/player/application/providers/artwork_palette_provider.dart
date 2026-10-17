import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../library/application/providers/library_providers.dart';

final artworkPaletteProvider = FutureProvider.autoDispose
    .family<ArtworkPalette?, int>((ref, songId) async {
      final bytes = await ref.watch(songArtworkProvider((songId, 32)).future);
      if (bytes == null || bytes.isEmpty) return null;
      return _extractPalette(bytes);
    });

@immutable
class ArtworkPalette {
  const ArtworkPalette(this.first, this.second);

  final Color first;
  final Color second;
}

Future<ArtworkPalette?> _extractPalette(Uint8List bytes) async {
  ui.Codec? codec;
  ui.Image? image;
  try {
    codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 32,
      targetHeight: 32,
    );
    image = (await codec.getNextFrame()).image;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return null;
    final colors = data.buffer.asUint8List();
    final half = image.width ~/ 2;
    return ArtworkPalette(
      _averageRegion(colors, image.width, image.height, 0, half),
      _averageRegion(colors, image.width, image.height, half, image.width),
    );
  } catch (_) {
    return null;
  } finally {
    image?.dispose();
    codec?.dispose();
  }
}

Color _averageRegion(
  Uint8List pixels,
  int width,
  int height,
  int startX,
  int endX,
) {
  var red = 0.0;
  var green = 0.0;
  var blue = 0.0;
  var weightTotal = 0.0;
  for (var y = 0; y < height; y += 2) {
    for (var x = startX; x < endX; x += 2) {
      final offset = (y * width + x) * 4;
      final r = pixels[offset].toDouble();
      final g = pixels[offset + 1].toDouble();
      final b = pixels[offset + 2].toDouble();
      final max = [r, g, b].reduce((a, value) => a > value ? a : value);
      final min = [r, g, b].reduce((a, value) => a < value ? a : value);
      final weight = ((max - min) / 255).clamp(0.25, 1.0);
      red += r * weight;
      green += g * weight;
      blue += b * weight;
      weightTotal += weight;
    }
  }
  if (weightTotal == 0) return Colors.blueGrey;
  return Color.fromARGB(
    255,
    (red / weightTotal).round(),
    (green / weightTotal).round(),
    (blue / weightTotal).round(),
  );
}
