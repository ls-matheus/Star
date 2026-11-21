import 'package:star_app/core/api/star_client_properties.dart';
import 'package:star_app/core/platform/star_platform.dart';
import 'package:star_dart/gateway.dart';

GatewayIdentifyProperties buildGatewayIdentifyProperties(
  StarClientProperties properties,
) {
  final bool isDesktop = isStarDesktopOs;
  final String? buildVersion =
      properties.clientVersion ?? properties.buildNumber?.toString();
  return GatewayIdentifyProperties(
    os: properties.os,
    browser: properties.browser,
    device: properties.device,
    osVersion: properties.osVersion,
    locale: properties.locale,
    systemLocale: properties.systemLocale,
    browserVersion: properties.browserVersion,
    buildTimestamp: properties.buildTimestamp,
    buildVersion: buildVersion,
    buildNumber: properties.buildNumber,
    betaNumber: properties.betaNumber,
    userAgent: properties.userAgent,
    releaseChannel: properties.releaseChannel,
    clientPlatform: properties.clientPlatform,
    clientRuntime: properties.clientRuntime,
    desktopAppVersion:
        properties.desktopAppVersion ?? (isDesktop ? buildVersion : null),
    desktopAppChannel:
        properties.desktopAppChannel ??
        (isDesktop ? properties.releaseChannel : null),
    desktopArch: properties.desktopArch ?? properties.architecture,
    desktopOs: properties.desktopOs ?? (isDesktop ? properties.os : null),
    e2eeCapable: true,
    mobile: isStarMobileOs,
  );
}
