abstract final class RouteNames {
  static const String home = '/';
  static const String player = '/player';
  static const String groupSongs = '/group-songs';
}

class GroupSongsArgs {
  const GroupSongsArgs({
    required this.isArtist,
    required this.id,
    required this.title,
  });

  final bool isArtist;
  final int id;
  final String title;
}
