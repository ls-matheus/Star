import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/constants/external_urls.dart';
import 'package:star_app/core/providers/instance/active_instance_provider.dart';
import 'package:star_app/features/shell/domain/service_status_incident.dart';
import 'package:star_app/features/shell/providers/service_status/service_status_incident_provider.dart';
import 'package:star_app/features/ui/text_link/star_text_link.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class ServiceStatusConnectionFooter extends ConsumerWidget {
  const ServiceStatusConnectionFooter({
    required this.promptStyle,
    required this.linkStyle,
    this.showPrompt = true,
    super.key,
  });

  final TextStyle promptStyle;
  final TextStyle linkStyle;
  final bool showPrompt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isActiveInstanceOfficialProvider)) {
      return const SizedBox.shrink();
    }
    final StarLocalizations strings = StarLocalizations.of(context);
    final ServiceStatusIncident? incident = ref.watch(
      serviceStatusIncidentReadProvider,
    );
    final String secondLinkUrl =
        incident?.url ?? ExternalUrls.serviceStatusHistory;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showPrompt) ...[
          Text(
            strings.splashConnectionIssuesPrompt,
            style: promptStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            StarTextLink(
              text: strings.splashStatusPageLink,
              url: ExternalUrls.serviceStatus,
              style: linkStyle,
            ),
            Text('·', style: promptStyle),
            StarTextLink(
              text: incident != null
                  ? strings.splashReadIncident
                  : strings.splashIncidentHistory,
              url: secondLinkUrl,
              style: linkStyle,
            ),
          ],
        ),
      ],
    );
  }
}

class OfficialInstanceStatusPageLink extends ConsumerWidget {
  const OfficialInstanceStatusPageLink({this.style, super.key});

  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isActiveInstanceOfficialProvider)) {
      return const SizedBox.shrink();
    }
    final StarLocalizations strings = StarLocalizations.of(context);
    return StarTextLink(
      text: strings.splashViewOnStatusPage,
      url: ExternalUrls.serviceStatus,
      style: style,
    );
  }
}
