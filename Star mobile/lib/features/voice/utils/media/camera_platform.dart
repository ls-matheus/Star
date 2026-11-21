import 'package:star_app/core/platform/star_platform.dart';

bool isMobileVoiceCameraPlatform() {
  return isStarMobileOs;
}

bool isNativeMobileVoiceCameraPlatform() {
  return isStarNativeMobileOs;
}
