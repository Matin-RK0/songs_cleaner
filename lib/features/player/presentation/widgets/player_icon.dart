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

class PlayerIcon extends StatelessWidget {
  const PlayerIcon(this.glyph, {super.key});

  final PlayerGlyph glyph;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = theme.size ?? AppPlayerMetrics.icon;
    return CustomPaint(
      size: Size.square(size),
      painter: _PlayerIconPainter(glyph, theme.color!),
    );
  }
}

class _PlayerIconPainter extends CustomPainter {
  const _PlayerIconPainter(this.glyph, this.color);

  final PlayerGlyph glyph;
  final Color color;

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
    canvas.drawPath(_GlyphPaths.paths[glyph]!, paint);
  }

  @override
  bool shouldRepaint(covariant _PlayerIconPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.color != color;
}

abstract final class _GlyphPaths {
  // Parsed once, never recreated during playback, animation or list rebuilds.
  static final Map<PlayerGlyph, Path> paths = {
    PlayerGlyph.play: Path()
      ..moveTo(7, 3.8)
      ..quadraticBezierTo(7, 2.3, 8.4, 3.2)
      ..lineTo(20, 10.8)
      ..quadraticBezierTo(21.5, 12, 20, 13.2)
      ..lineTo(8.4, 20.8)
      ..quadraticBezierTo(7, 21.7, 7, 20.2)
      ..close(),
    PlayerGlyph.pause: Path()
      ..addRRect(RRect.fromLTRBR(6, 3, 9, 21, const Radius.circular(1.5)))
      ..addRRect(RRect.fromLTRBR(15, 3, 18, 21, const Radius.circular(1.5))),
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
      ..addRRect(RRect.fromLTRBR(2, 5, 4.5, 19, const Radius.circular(1)))
      ..moveTo(4.5, 12)
      ..lineTo(12.5, 5.5)
      ..quadraticBezierTo(13.5, 4.5, 13.5, 6)
      ..lineTo(13.5, 18)
      ..quadraticBezierTo(13.5, 19.5, 12.5, 18.5)
      ..close()
      ..moveTo(13, 12)
      ..lineTo(21, 5.5)
      ..quadraticBezierTo(22, 4.5, 22, 6)
      ..lineTo(22, 18)
      ..quadraticBezierTo(22, 19.5, 21, 18.5)
      ..close();
    if (!forward) return path;
    return path
        .transform(Matrix4.diagonal3Values(-1, 1, 1).storage)
        .shift(const Offset(24, 0));
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
