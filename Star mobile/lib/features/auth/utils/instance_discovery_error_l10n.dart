import 'package:star_app/core/instance/instance_compatibility_messages.dart';
import 'package:star_app/core/instance/instance_endpoint_normalizer.dart';
import 'package:star_app/features/auth/providers/instance_selector_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';

String instanceDiscoveryErrorText(
  InstanceSelectorState state,
  StarLocalizations l10n,
) {
  final String domain = const InstanceEndpointNormalizer().describeApiEndpoint(
    state.instanceUrl,
  );
  return instanceDiscoveryFailureMessage(
    reason: state.discoveryFailureReason,
    errorMessage: state.errorMessage,
    domain: domain,
    l10n: l10n,
  );
}
