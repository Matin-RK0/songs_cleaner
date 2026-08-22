sealed class Failure {
  const Failure();
}

final class PermissionFailure extends Failure {
  const PermissionFailure({this.permanentlyDenied = false});

  final bool permanentlyDenied;
}

final class LibraryLoadFailure extends Failure {
  const LibraryLoadFailure(this.cause);

  final Object? cause;
}

final class SongDeleteFailure extends Failure {
  const SongDeleteFailure(this.path, this.cause);

  final String path;
  final Object? cause;
}

final class PlaybackFailure extends Failure {
  const PlaybackFailure(this.songId, this.cause);

  final int songId;
  final Object? cause;
}

final class UnknownFailure extends Failure {
  const UnknownFailure(this.cause);

  final Object? cause;
}
