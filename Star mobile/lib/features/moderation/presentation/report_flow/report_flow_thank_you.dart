import 'package:star_app/core/instance/instance_constants.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/moderation/presentation/report_flow/report_flow_parts.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class ReportFlowBlockTarget {
  const ReportFlowBlockTarget({required this.userId, required this.name});

  final String userId;
  final String name;
}

class ReportFlowThankYou extends StatelessWidget {
  const ReportFlowThankYou({
    required this.reportSent,
    required this.endedOnStartScreen,
    required this.selfHosted,
    required this.blockTarget,
    required this.blocked,
    required this.blocking,
    required this.onBlock,
    super.key,
  });

  final bool reportSent;
  final bool endedOnStartScreen;
  final bool selfHosted;
  final ReportFlowBlockTarget? blockTarget;
  final bool blocked;
  final bool blocking;
  final VoidCallback onBlock;

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final colors = context.colors;
    final layout = context.layout;
    final ReportFlowBlockTarget? target = blockTarget;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          reportSent && selfHosted
              ? l10n.reportFlowThankYouBodySelfHosted
              : reportSent
              ? l10n.reportFlowThankYouBody(
                  InstanceConstants.defaultProductName,
                )
              : endedOnStartScreen
              ? l10n.reportFlowThankYouNoReportBody
              : l10n.reportFlowThankYouNoReportBodyShort,
          style: context.textStyles.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        if (target != null) ...[
          SizedBox(height: layout.s4),
          ReportFlowSectionHeading(l10n.reportFlowMoreYouCanDo),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: layout.s4,
              vertical: layout.s3,
            ),
            decoration: BoxDecoration(
              borderRadius: layout.radiusLg,
              border: Border.all(color: colors.backgroundModifierAccent),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.reportFlowBlockName(target.name),
                        style: context.textStyles.bodyMedium.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: layout.s1),
                      Text(
                        l10n.reportFlowBlockDescription,
                        style: context.textStyles.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: layout.s3),
                if (blocked)
                  StarButton.secondary(
                    label: l10n.reportFlowBlockedButton,
                    size: StarButtonSize.small,
                    fitContent: true,
                  )
                else
                  StarButton.dangerPrimary(
                    onPressed: blocking ? null : onBlock,
                    isLoading: blocking,
                    label: l10n.reportFlowBlockButton,
                    size: StarButtonSize.small,
                    fitContent: true,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
