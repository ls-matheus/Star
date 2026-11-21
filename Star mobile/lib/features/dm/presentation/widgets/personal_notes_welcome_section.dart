import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class PersonalNotesWelcomeSection extends ConsumerWidget {
  const PersonalNotesWelcomeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final String? userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      return const SizedBox.shrink();
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            StarAvatar.user(
              userId: userId,
              fallbackText: l10n.personalNotesTitle,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.personalNotesTitle,
              style: context.textStyles.channelName.copyWith(
                fontSize: 24,
                color: context.colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            PhosphorIcon(
              PhosphorIconsFill.notePencil,
              size: 20,
              color: context.colors.textPrimaryMuted,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.personalNotesSubtitle,
              style: context.textStyles.bodyMedium.copyWith(
                color: context.colors.textPrimaryMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
