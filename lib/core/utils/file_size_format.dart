extension FileSizeFormat on int {
  String get readableFileSize {
    if (this < 1024) return '$this B';
    final kilobytes = this / 1024;
    if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} KB';
    final megabytes = kilobytes / 1024;
    if (megabytes < 1024) return '${megabytes.toStringAsFixed(1)} MB';
    return '${(megabytes / 1024).toStringAsFixed(1)} GB';
  }
}
