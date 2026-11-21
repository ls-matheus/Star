import 'package:star_app/core/platform/star_platform.dart'
    show isStarDesktopOs, isStarMobileOs;

export 'package:star_app/core/platform/star_platform.dart'
    show isStarDesktopOs, isStarMobileOs;

bool get isDesktopOs => isStarDesktopOs;

bool get isMobileNative => isStarMobileOs;
