import 'package:star_app/core/database/star_database.dart';
import 'package:star_app/core/router/app_location_persistence.dart';
import 'package:star_app/core/router/guild_root_redirect.dart';
import 'package:star_app/core/router/navigator_route_location.dart';
import 'package:star_app/material_ui.dart';

class ChannelPersistenceObserver extends NavigatorObserver {
  final StarDatabase db;

  ChannelPersistenceObserver(this.db);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _saveLocation(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _saveLocation(newRoute);
    }
  }

  void _saveLocation(Route<dynamic> route) {
    final String? uri = persistedNavigatorRouteLocation(
      name: route.settings.name,
      arguments: route.settings.arguments,
    );
    if (uri == null) {
      return;
    }
    persistAppLocation(db, uri);
    if (!uri.startsWith('/channels/')) {
      return;
    }
    persistGuildChannelFromLocation(db, uri);
  }
}
