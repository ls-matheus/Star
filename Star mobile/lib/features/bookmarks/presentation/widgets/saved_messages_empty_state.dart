import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/presentation/widgets/desktop_settings_text.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';

class SavedMessagesEmptyState extends ConsumerWidget {
  const SavedMessagesEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final StarLocalizations l10n = StarLocalizations.of(context);
    if (usesDesktopPointerUi(context)) {
      return _buildDesktop(context, l10n);
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              PhosphorIconsBold.sparkle,
              size: 80,
              color: colors.textPrimaryMuted,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.savedMessagesEmptyTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.savedMessagesEmptyBody,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.textPrimaryMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktop(BuildContext context, StarLocalizations l10n) {
    final colors = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 400),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: <Widget>[
            PhosphorIcon(
              PhosphorIconsRegular.sparkle,
              size: 80,
              color: colors.textPrimaryMuted,
            ),
            Text(
              l10n.savedMessagesEmptyTitle,
              textAlign: TextAlign.center,
              style: desktopSettingsTitleStyle(context),
            ),
            Text(
              l10n.savedMessagesEmptyBody,
              textAlign: TextAlign.center,
              style: desktopSettingsSubtitleStyle(context),
            ),
          ],
        ),
      ),
    );
  }
}
