import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

const String _kFallbackErrorMessage = 'An error occurred';

class StarRenderErrorPlaceholder extends StatelessWidget {
  const StarRenderErrorPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final StarColorTheme colors = _resolveColors(context);
    final String message = _resolveMessage(context);
    final TextStyle textStyle = _resolveTextStyle(context, colors);
    return Semantics(
      label: message,
      child: ColoredBox(
        color: colors.backgroundPrimary,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                PhosphorIcon(
                  PhosphorIconsFill.bug,
                  size: 48,
                  color: colors.textPrimaryMuted,
                ),
                const SizedBox(height: 12),
                Text(message, style: textStyle, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  StarColorTheme _resolveColors(BuildContext context) {
    try {
      return Theme.of(context).extension<StarColorTheme>() ??
          buildDarkColorTheme();
    } on Object {
      return buildDarkColorTheme();
    }
  }

  String _resolveMessage(BuildContext context) {
    final StarLocalizations? l10n = Localizations.of<StarLocalizations>(
      context,
      StarLocalizations,
    );
    return l10n?.genericError ?? _kFallbackErrorMessage;
  }

  TextStyle _resolveTextStyle(BuildContext context, StarColorTheme colors) {
    try {
      final StarTextTheme? textTheme = Theme.of(
        context,
      ).extension<StarTextTheme>();
      if (textTheme != null) {
        return textTheme.bodySmall.copyWith(color: colors.textPrimaryMuted);
      }
    } on Object {
      // Fall through to default text style.
    }
    return TextStyle(fontSize: 14, color: colors.textPrimaryMuted);
  }
}
