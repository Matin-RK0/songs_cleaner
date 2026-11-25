/// A normalized point in the source image and a zoom relative to cover-fit.
class PhotoFraming {
  const PhotoFraming({this.x = 0.5, this.y = 0.5, this.zoom = 1});

  static const double minZoom = 1;
  static const double maxZoom = 4;

  final double x;
  final double y;
  final double zoom;

  factory PhotoFraming.fromJson(Object? value) {
    if (value is! Map) return const PhotoFraming();
    double read(String key, double fallback, double min, double max) {
      final number = value[key];
      return number is num && number.isFinite
          ? number.toDouble().clamp(min, max)
          : fallback;
    }

    return PhotoFraming(
      x: read('x', 0.5, 0, 1),
      y: read('y', 0.5, 0, 1),
      zoom: read('zoom', minZoom, minZoom, maxZoom),
    );
  }

  Map<String, double> toJson() => {'x': x, 'y': y, 'zoom': zoom};
}
