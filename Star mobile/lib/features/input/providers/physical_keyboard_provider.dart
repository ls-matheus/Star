import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/platform/star_platform.dart';
import 'package:star_app/core/platform/physical_keyboard.dart';

final physicalKeyboardConnectedProvider = StreamProvider<bool>((ref) {
  return watchPhysicalKeyboardConnected(supported: isStarNativeMobileOs);
});
