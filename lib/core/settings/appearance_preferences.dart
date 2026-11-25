import 'photo_framing.dart';

enum AppBackgroundKind { standard, color, photo }

class AppearancePreferences {
  const AppearancePreferences({
    this.backgroundColor,
    this.photoPath,
    this.photoDimming = defaultDimming,
    this.photoFraming = const PhotoFraming(),
    this.foregroundColor,
    this.systemTheme = false,
  });

  // The minimum keeps text readable even over a completely white or black photo.
  static const minDimming = 0.65;
  static const defaultDimming = 0.78;

  final int? backgroundColor;
  final String? photoPath;
  final double photoDimming;
  final PhotoFraming photoFraming;
  final int? foregroundColor;
  final bool systemTheme;

  AppBackgroundKind get backgroundKind => photoPath != null
      ? AppBackgroundKind.photo
      : backgroundColor != null
      ? AppBackgroundKind.color
      : AppBackgroundKind.standard;

  AppearancePreferences copyWith({
    int? backgroundColor,
    String? photoPath,
    double? photoDimming,
    PhotoFraming? photoFraming,
    int? foregroundColor,
    bool? systemTheme,
    bool clearBackground = false,
    bool clearForeground = false,
  }) => AppearancePreferences(
    backgroundColor: clearBackground || photoPath != null
        ? null
        : backgroundColor ?? this.backgroundColor,
    photoPath: clearBackground || backgroundColor != null
        ? null
        : photoPath ?? this.photoPath,
    photoDimming: photoDimming == null
        ? this.photoDimming
        : normalizeDimming(photoDimming),
    photoFraming:
        photoFraming ??
        (clearBackground || backgroundColor != null || photoPath != null
            ? const PhotoFraming()
            : this.photoFraming),
    foregroundColor: clearForeground
        ? null
        : foregroundColor ?? this.foregroundColor,
    systemTheme: systemTheme ?? this.systemTheme,
  );

  static double normalizeDimming(double value) =>
      value.isFinite ? value.clamp(minDimming, 1.0) : defaultDimming;

  factory AppearancePreferences.fromJson(Map<String, Object?> json) {
    final path = json['photoPath'];
    final dimming = json['photoDimming'];
    final photo = path is String && path.isNotEmpty ? path : null;
    int? color(Object? value) =>
        value is int && value >= 0 && value <= 0xffffffff
        ? value | 0xff000000
        : null;
    return AppearancePreferences(
      backgroundColor: photo == null ? color(json['backgroundColor']) : null,
      photoPath: photo,
      photoFraming: PhotoFraming.fromJson(json['photoFraming']),
      photoDimming: dimming is num
          ? normalizeDimming(dimming.toDouble())
          : defaultDimming,
      foregroundColor: color(json['foregroundColor']),
      systemTheme: json['systemTheme'] == true,
    );
  }

  Map<String, Object?> toJson() => {
    'backgroundColor': backgroundColor,
    'photoPath': photoPath,
    'photoDimming': photoDimming,
    if (photoPath != null) 'photoFraming': photoFraming.toJson(),
    'foregroundColor': foregroundColor,
    'systemTheme': systemTheme,
  };
}
