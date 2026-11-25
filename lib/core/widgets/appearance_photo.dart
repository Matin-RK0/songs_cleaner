import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../settings/photo_framing.dart';
import '../theme/photo_frame_geometry.dart';

class AppearancePhotoSource extends StatefulWidget {
  const AppearancePhotoSource({
    super.key,
    required this.path,
    required this.builder,
  });

  final String path;
  final Widget Function(BuildContext, ui.Image?, bool failed) builder;

  @override
  State<AppearancePhotoSource> createState() => _AppearancePhotoSourceState();
}

class _AppearancePhotoSourceState extends State<AppearancePhotoSource> {
  ImageStream? _stream;
  ImageInfo? _info;
  bool _failed = false;
  late final _listener = ImageStreamListener(
    _receiveImage,
    onError: (error, stack) {
      setState(() => _failed = true);
    },
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant AppearancePhotoSource oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.path != oldWidget.path) _resolve();
  }

  void _resolve() {
    final stream = FileImage(File(widget.path))
        .resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _releaseImage();
    _failed = false;
    _stream = stream..addListener(_listener);
  }

  void _receiveImage(ImageInfo info, bool synchronous) {
    void receive() {
      _releaseImage();
      _info = info;
      _failed = false;
    }

    if (synchronous) {
      receive();
    } else {
      setState(receive);
    }
  }

  void _releaseImage() {
    final previous = _info;
    _info = null;
    // The previous painter may still be attached until this frame finishes.
    if (previous != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _releaseImage();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _info?.image, _failed);
}

class FramedAppearancePhoto extends StatelessWidget {
  const FramedAppearancePhoto({
    super.key,
    required this.image,
    required this.framing,
  });

  final ui.Image image;
  final PhotoFraming framing;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _PhotoPainter(image, framing),
    child: const SizedBox.expand(),
  );
}

class _PhotoPainter extends CustomPainter {
  const _PhotoPainter(this.image, this.framing);

  final ui.Image image;
  final PhotoFraming framing;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    canvas.drawImageRect(
      image,
      PhotoFrameGeometry.crop(imageSize, size, framing),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.low,
    );
  }

  @override
  bool shouldRepaint(covariant _PhotoPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.framing.x != framing.x ||
      oldDelegate.framing.y != framing.y ||
      oldDelegate.framing.zoom != framing.zoom;
}
