abstract final class RouteNames {
  static const String home = '/';
  static const String player = '/player';
  static const String search = '/search';
  static const String groupSongs = '/group-songs';
  static const String settings = '/settings';
  static const String lockScreen = '/lock-screen';
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
