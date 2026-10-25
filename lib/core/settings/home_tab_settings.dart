enum HomeTab { songs, artists, albums, playlists, telegram }

/// Stable tab identities keep navigation independent of the display order.
class HomeTabSettings {
  const HomeTabSettings({
    this.order = HomeTab.values,
    this.defaultTab = HomeTab.songs,
  });

  final List<HomeTab> order;
  final HomeTab defaultTab;

  factory HomeTabSettings.fromJson(Map<String, dynamic> json) {
    final byName = {for (final tab in HomeTab.values) tab.name: tab};
    final rawOrder = json['order'];
    final order = <HomeTab>{
      if (rawOrder is List)
        for (final name in rawOrder) ?byName[name],
      ...HomeTab.values,
    };
    return HomeTabSettings(
      order: List.unmodifiable(order),
      defaultTab: byName[json['defaultTab']] ?? HomeTab.songs,
    );
  }

  HomeTabSettings reordered(int oldIndex, int newIndex) {
    final tabs = [...order];
    tabs.insert(newIndex, tabs.removeAt(oldIndex));
    return HomeTabSettings(
      order: List.unmodifiable(tabs),
      defaultTab: defaultTab,
    );
  }

  HomeTabSettings withDefault(HomeTab tab) =>
      HomeTabSettings(order: order, defaultTab: tab);

  Map<String, Object> toJson() => {
    'order': order.map((tab) => tab.name).toList(),
    'defaultTab': defaultTab.name,
  };
}
