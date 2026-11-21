import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/shell/navigation/drawer_navigation_coordinator.dart';

void returnToFavoritesList(ProviderContainer container) {
  DrawerNavigationCoordinator.revealDrawer(container);
}

bool isFavoritesChannelRoute(String location) {
  return location.startsWith('/channels/@favorites/');
}
