import 'package:star_app/core/instance/instance_discovery_service.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';

String instanceCompatibilityBody(
  InstanceDiscoveryFailureReason reason,
  String domain,
  StarLocalizations l10n,
) {
  switch (reason) {
    case InstanceDiscoveryFailureReason.invalidDiscoveryResponse:
      return l10n.instanceInvalidDiscoveryResponse;
    case InstanceDiscoveryFailureReason.instanceOutdated:
      return l10n.instanceOutdatedForClient(domain);
    case InstanceDiscoveryFailureReason.requiresNewerClient:
      return l10n.instanceRequiresNewerClient(domain);
    case InstanceDiscoveryFailureReason.insecureConnection:
      return l10n.instanceInsecureConnection(domain);
  }
}

String instanceDiscoveryFailureMessage({
  required InstanceDiscoveryFailureReason? reason,
  required String? errorMessage,
  required String domain,
  required StarLocalizations l10n,
}) {
  if (reason != null) {
    return instanceCompatibilityBody(reason, domain, l10n);
  }
  if (errorMessage != null && errorMessage.isNotEmpty) {
    return errorMessage;
  }
  if (domain.isNotEmpty) {
    return l10n.instanceConnectFailedDomain(domain);
  }
  return l10n.instanceConnectFailed;
}
