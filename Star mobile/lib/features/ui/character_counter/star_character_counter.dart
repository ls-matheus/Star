import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/features/ui/tooltip/star_tooltip.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class StarCharacterCounter extends StatelessWidget {
  const StarCharacterCounter({
    required this.current,
    required this.max,
    this.canUpgrade = false,
    this.premiumMaxLength,
    this.onUpgradePressed,
    this.showTooltip = true,
    super.key,
  });

  final int current;
  final int max;
  final bool canUpgrade;
  final int? premiumMaxLength;
  final VoidCallback? onUpgradePressed;
  final bool showTooltip;

  static const int _kNearingThreshold = 50;

  @override
  Widget build(BuildContext context) {
    final int remaining = max - current;
    final bool isOverLimit = remaining < 0;
    final bool isNearingLimit = remaining < _kNearingThreshold;
    final Color color = isOverLimit || isNearingLimit
        ? context.colors.statusDanger
        : context.colors.textTertiary;
    final TextStyle textStyle = context.textStyles.smallText.copyWith(
      color: color,
    );
    final StarLocalizations l10n = StarLocalizations.of(context);
    final bool needsPremium =
        canUpgrade &&
        premiumMaxLength != null &&
        onUpgradePressed != null &&
        (isNearingLimit || isOverLimit);
    final String tooltipText = needsPremium
        ? l10n.characterCounterRemainingPlutoniumUpsell(
            remaining,
            l10n.getPlutonium,
            premiumMaxLength!,
          )
        : isOverLimit
        ? l10n.characterCounterTooLong
        : l10n.characterCounterRemaining(remaining);
    final Widget counterLabel = ExcludeSemantics(
      child: Text('$remaining', style: textStyle, textAlign: TextAlign.end),
    );
    final Widget counterChild = needsPremium
        ? TextButton(
            onPressed: onUpgradePressed,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: color,
            ),
            child: counterLabel,
          )
        : counterLabel;
    final Widget semanticsChild = Semantics(
      label: tooltipText,
      liveRegion: true,
      child: counterChild,
    );
    if (!showTooltip) {
      return semanticsChild;
    }
    return StarTooltip(message: tooltipText, child: semanticsChild);
  }
}

@StarWidgetPreview(name: 'Normal', group: 'StarCharacterCounter')
Widget starCharacterCounterNormalPreview() {
  return const StarCharacterCounter(current: 24, max: 100);
}

@StarWidgetPreview(name: 'Near limit', group: 'StarCharacterCounter')
Widget starCharacterCounterWarnPreview() {
  return const StarCharacterCounter(current: 85, max: 100);
}

@StarWidgetPreview(name: 'Over limit', group: 'StarCharacterCounter')
Widget starCharacterCounterOverPreview() {
  return const StarCharacterCounter(current: 120, max: 100);
}
