import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/moderation/domain/iar_context.dart';
import 'package:star_app/features/moderation/domain/report_flow.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class ReportFlowOptionList extends StatelessWidget {
  const ReportFlowOptionList({
    required this.options,
    required this.onChoose,
    super.key,
  });

  final List<ReportFlowOption> options;
  final ValueChanged<ReportFlowOption> onChoose;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return StarMenuGroup(
      children: <Widget>[
        for (final ReportFlowOption option in options)
          StarBottomSheetMenuItem(
            key: ValueKey<String>('report-flow-option-${option.id}'),
            label: option.label,
            onTap: () => onChoose(option),
            trailing: PhosphorIcon(
              option.outcome.type == ReportFlowOutcomeType.link
                  ? PhosphorIconsBold.arrowSquareOut
                  : PhosphorIconsBold.caretRight,
              size: 16,
              color: colors.textSecondary,
            ),
          ),
      ],
    );
  }
}

String reportFlowLinkUrl(String url, IarContext target) {
  const String reportPath = '/report';
  final Uri? uri = Uri.tryParse(url);
  if (uri == null || !uri.path.endsWith(reportPath)) {
    return url;
  }
  final String basePath = uri.path.substring(
    0,
    uri.path.length - reportPath.length,
  );
  final Map<String, String> prefill = switch (target) {
    IarMessageContext(:final message, :final guildId) => <String, String>{
      'type': 'message',
      'message_link': Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
        path:
            '$basePath/channels/${guildId ?? '@me'}/${message.channelId}/${message.id}',
      ).toString(),
    },
    IarUserContext(:final userId) => <String, String>{
      'type': 'user',
      'user_id': userId,
    },
    IarGuildContext() => <String, String>{'type': 'guild'},
  };
  return uri
      .replace(
        queryParameters: <String, String>{...uri.queryParameters, ...prefill},
      )
      .toString();
}
