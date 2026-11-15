import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_player_metrics.dart';

/// Lightweight, consistently weighted player glyphs in a 24-unit viewport.
enum PlayerGlyph {
  play,
  pause,
  previous,
  next,
  shuffle,
  repeat,
  repeatOne,
  queue,
  favorite,
  favoriteOutline,
  add,
  collapse,
  equalizer,
  more,
}

class PlayerIcon extends StatefulWidget {
  const PlayerIcon(this.glyph, {super.key});

  final PlayerGlyph glyph;

  @override
  State<PlayerIcon> createState() => _PlayerIconState();
}

class _PlayerIconState extends State<PlayerIcon> {
  @override
  void reassemble() {
    super.reassemble();
    _GlyphPaths.invalidate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = theme.size ?? AppPlayerMetrics.icon;
    return CustomPaint(
      size: Size.square(size),
      painter: _PlayerIconPainter(widget.glyph, theme.color!),
    );
  }
}

class _PlayerIconPainter extends CustomPainter {
  _PlayerIconPainter(this.glyph, this.color) : path = _GlyphPaths.paths[glyph]!;

  final PlayerGlyph glyph;
  final Color color;
  final Path path;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final filled = switch (glyph) {
      PlayerGlyph.play ||
      PlayerGlyph.pause ||
      PlayerGlyph.previous ||
      PlayerGlyph.next ||
      PlayerGlyph.favorite ||
      PlayerGlyph.more => true,
      _ => false,
    };
    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.65
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PlayerIconPainter oldDelegate) =>
      oldDelegate.path != path || oldDelegate.color != color;
}

abstract final class _GlyphPaths {
  // Cached across frames/builds, but refreshed after code changes in debug.
  static Map<PlayerGlyph, Path>? _cache;
  static Map<PlayerGlyph, Path> get paths => _cache ??= _createPaths();
  static void invalidate() => _cache = null;

  static Map<PlayerGlyph, Path> _createPaths() => {
    PlayerGlyph.play: _roundedPolygon(const [
      Offset(7, 3),
      Offset(21, 12),
      Offset(7, 21),
    ], 4),
    PlayerGlyph.pause: Path()
      ..addRRect(RRect.fromLTRBR(6, 4, 10, 20, const Radius.circular(2)))
      ..addRRect(RRect.fromLTRBR(14, 4, 18, 20, const Radius.circular(2))),
    PlayerGlyph.previous: _skip(false),
    PlayerGlyph.next: _skip(true),
    PlayerGlyph.shuffle: Path()
      ..moveTo(3, 6)
      ..lineTo(5.5, 6)
      ..cubicTo(10, 6, 12, 18, 16.5, 18)
      ..lineTo(21, 18)
      ..moveTo(18, 15)
      ..lineTo(21, 18)
      ..lineTo(18, 21)
      ..moveTo(3, 18)
      ..lineTo(5.5, 18)
      ..cubicTo(10, 18, 12, 6, 16.5, 6)
      ..lineTo(21, 6)
      ..moveTo(18, 3)
      ..lineTo(21, 6)
      ..lineTo(18, 9),
    PlayerGlyph.repeat: _repeat(),
    PlayerGlyph.repeatOne: _repeat()
      ..moveTo(11, 11)
      ..lineTo(12.5, 10)
      ..lineTo(12.5, 14),
    PlayerGlyph.queue: Path()
      ..moveTo(3, 5)
      ..lineTo(21, 5)
      ..moveTo(3, 11)
      ..lineTo(10, 11)
      ..moveTo(3, 17)
      ..lineTo(7, 17)
      ..moveTo(16, 18)
      ..lineTo(16, 10)
      ..quadraticBezierTo(20, 10, 21, 14)
      ..moveTo(16, 18)
      ..cubicTo(16, 14, 10, 15, 11, 19)
      ..cubicTo(12, 22, 16, 21, 16, 18),
    PlayerGlyph.favorite: _heart(),
    PlayerGlyph.favoriteOutline: _heart(),
    PlayerGlyph.add: Path()
      ..moveTo(12, 3)
      ..lineTo(12, 21)
      ..moveTo(3, 12)
      ..lineTo(21, 12),
    PlayerGlyph.collapse: Path()
      ..moveTo(3, 8)
      ..lineTo(12, 17)
      ..lineTo(21, 8),
    PlayerGlyph.equalizer: Path()
      ..moveTo(4, 20)
      ..lineTo(4, 11)
      ..moveTo(8, 20)
      ..lineTo(8, 4)
      ..moveTo(12, 20)
      ..lineTo(12, 9)
      ..moveTo(16, 20)
      ..lineTo(16, 13)
      ..moveTo(20, 20)
      ..lineTo(20, 15),
    PlayerGlyph.more: Path()
      ..addOval(Rect.fromCircle(center: const Offset(12, 5), radius: 1.4))
      ..addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 1.4))
      ..addOval(Rect.fromCircle(center: const Offset(12, 19), radius: 1.4)),
  };

  static Path _skip(bool forward) {
    final path = Path()
      ..addRRect(RRect.fromLTRBR(2, 5, 5, 19, const Radius.circular(1.5)))
      ..addPath(
        _roundedPolygon(const [
          Offset(4.5, 12),
          Offset(13.5, 5),
          Offset(13.5, 19),
        ], 3),
        Offset.zero,
      )
      ..addPath(
        _roundedPolygon(const [
          Offset(13, 12),
          Offset(22, 5),
          Offset(22, 19),
        ], 3),
        Offset.zero,
      );
    if (!forward) return path;
    return path
        .transform(Matrix4.diagonal3Values(-1, 1, 1).storage)
        .shift(const Offset(24, 0));
  }

  static Path _roundedPolygon(List<Offset> points, double radius) {
    final path = Path();
    for (var index = 0; index < points.length; index++) {
      final vertex = points[index];
      final incoming =
          points[(index - 1 + points.length) % points.length] - vertex;
      final outgoing = points[(index + 1) % points.length] - vertex;
      final distance = math.min(
        radius,
        math.min(incoming.distance, outgoing.distance) / 2,
      );
      final entry = vertex + incoming / incoming.distance * distance;
      final exit = vertex + outgoing / outgoing.distance * distance;
      if (index == 0) {
        path.moveTo(entry.dx, entry.dy);
      } else {
        path.lineTo(entry.dx, entry.dy);
      }
      path.quadraticBezierTo(vertex.dx, vertex.dy, exit.dx, exit.dy);
    }
    return path..close();
  }

  static Path _repeat() => Path()
    ..moveTo(20, 10)
    ..lineTo(20, 8)
    ..quadraticBezierTo(20, 5, 17, 5)
    ..lineTo(4, 5)
    ..moveTo(7, 2)
    ..lineTo(4, 5)
    ..lineTo(7, 8)
    ..moveTo(4, 14)
    ..lineTo(4, 16)
    ..quadraticBezierTo(4, 19, 7, 19)
    ..lineTo(20, 19)
    ..moveTo(17, 16)
    ..lineTo(20, 19)
    ..lineTo(17, 22);

  static Path _heart() => Path()
    ..moveTo(12, 21)
    ..cubicTo(10, 19, 2, 14, 2, 8)
    ..cubicTo(2, 2, 9, 1, 12, 6)
    ..cubicTo(15, 1, 22, 2, 22, 8)
    ..cubicTo(22, 14, 14, 19, 12, 21)
    ..close();
}
