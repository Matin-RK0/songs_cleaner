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
  const ArtworkPalette(this.first, this.second, this.third);

  final Color first;
  final Color second;
  final Color third;
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
    final extracted = _extractDistinctPixels(colors, image.width, image.height);
    return ArtworkPalette(extracted[0], extracted[1], extracted[2]);
  } catch (_) {
    return null;
  } finally {
    image?.dispose();
    codec?.dispose();
  }
}

List<Color> _extractDistinctPixels(Uint8List pixels, int width, int height) {
  final allSamples = <Color>[];
  final samples = <Color>[];
  for (var y = 0; y < height; y += 2) {
    for (var x = 0; x < width; x += 2) {
      final offset = (y * width + x) * 4;
      final color = Color.fromARGB(
        pixels[offset + 3],
        pixels[offset],
        pixels[offset + 1],
        pixels[offset + 2],
      );
      allSamples.add(color);
      final hsl = HSLColor.fromColor(color);
      if (hsl.saturation >= 0.16 &&
          hsl.lightness >= 0.10 &&
          hsl.lightness <= 0.90) {
        samples.add(color);
      }
    }
  }
  if (samples.isEmpty) samples.addAll(allSamples);
  if (samples.isEmpty) {
    return const [Colors.black, Colors.black, Colors.black];
  }

  samples.sort(
    (first, second) => HSLColor.fromColor(
      second,
    ).saturation.compareTo(HSLColor.fromColor(first).saturation),
  );
  final selected = <Color>[samples.first];
  while (selected.length < 3) {
    var best = samples.first;
    var bestDistance = -1.0;
    for (final candidate in samples) {
      final distance = selected
          .map((color) => _colorDistance(candidate, color))
          .reduce((a, b) => a < b ? a : b);
      if (distance > bestDistance) {
        best = candidate;
        bestDistance = distance;
      }
    }
    selected.add(best);
  }
  return selected;
}

double _colorDistance(Color first, Color second) {
  final red = first.r - second.r;
  final green = first.g - second.g;
  final blue = first.b - second.b;
  return red * red + green * green + blue * blue;
}
