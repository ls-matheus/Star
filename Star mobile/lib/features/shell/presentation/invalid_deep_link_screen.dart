import 'package:star_app/core/router/route_names.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:go_router/go_router.dart';

class InvalidDeepLinkScreen extends StatelessWidget {
  const InvalidDeepLinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final layout = context.layout;
    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: layout.s6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: context.colors.backgroundTertiary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: PhosphorIcon(
                    PhosphorIconsFill.linkBreak,
                    size: 36,
                    color: context.colors.textTertiaryMuted,
                  ),
                ),
              ),
              SizedBox(height: layout.s4),
              Text(
                l10n.invalidDeepLinkTitle,
                textAlign: TextAlign.center,
                style: context.textStyles.heading.copyWith(
                  color: context.colors.textPrimary,
                ),
              ),
              SizedBox(height: layout.s2),
              Text(
                l10n.invalidDeepLinkDescription,
                textAlign: TextAlign.center,
                style: context.textStyles.bodySmall.copyWith(
                  color: context.colors.textSecondary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: layout.s6),
              SizedBox(
                width: double.infinity,
                child: StarButton.primary(
                  label: l10n.invalidDeepLinkGoHomeButton,
                  onPressed: () => context.go(RoutePaths.me),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
