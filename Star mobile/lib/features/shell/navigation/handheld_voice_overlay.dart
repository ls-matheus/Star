import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';

bool isHandheldVoiceOverlayForContainer(ProviderContainer container) {
  final BuildContext? context = container
      .read(starRouterProvider)
      .routerDelegate
      .navigatorKey
      .currentContext;
  if (context == null) {
    return false;
  }
  return isHandheldVoiceOverlay(context);
}
