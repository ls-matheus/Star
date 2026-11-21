import 'dart:async';

import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/focus_ring/star_focus_ring.dart';
import 'package:star_app/features/ui/tooltip/star_tooltip.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/utils/clipboard_utils.dart';

enum StarSettingsHeadingLinkTarget { section, page }

class StarSettingsHeadingLinkButton extends StatefulWidget {
  const StarSettingsHeadingLinkButton({
    required this.href,
    this.target = StarSettingsHeadingLinkTarget.section,
    super.key,
  });

  final String href;
  final StarSettingsHeadingLinkTarget target;

  @override
  State<StarSettingsHeadingLinkButton> createState() =>
      _StarSettingsHeadingLinkButtonState();
}

class _StarSettingsHeadingLinkButtonState
    extends State<StarSettingsHeadingLinkButton> {
  static const Duration _copiedFeedbackDuration = Duration(seconds: 2);

  final ValueNotifier<bool> _copied = ValueNotifier<bool>(false);
  Timer? _copiedReset;

  @override
  void dispose() {
    _copiedReset?.cancel();
    _copied.dispose();
    super.dispose();
  }

  String _copyLabel(StarLocalizations l10n) {
    return switch (widget.target) {
      StarSettingsHeadingLinkTarget.section =>
        l10n.userSettingsCopyLinkToSection,
      StarSettingsHeadingLinkTarget.page => l10n.userSettingsCopyLinkToPage,
    };
  }

  Future<void> _copy(BuildContext context) async {
    await copyToClipboard(context: context, value: widget.href);
    if (!mounted) {
      return;
    }
    _copiedReset?.cancel();
    _copied.value = true;
    _copiedReset = Timer(_copiedFeedbackDuration, () {
      if (mounted) {
        _copied.value = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = StarLocalizations.of(context);
    final colors = context.colors;

    return ValueListenableBuilder<bool>(
      valueListenable: _copied,
      builder: (context, copied, _) {
        final String label = copied
            ? l10n.giftSettingsCopied
            : _copyLabel(l10n);
        final Color iconColor = copied
            ? colors.textPrimary
            : colors.textTertiary;

        return StarTooltip(
          message: label,
          child: StarFocusRing(
            focused: false,
            child: Semantics(
              button: true,
              label: label,
              child: InkWell(
                onTap: () => unawaited(_copy(context)),
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: Center(
                    child: PhosphorIcon(
                      copied ? PhosphorIconsBold.check : PhosphorIconsBold.link,
                      size: 15,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
