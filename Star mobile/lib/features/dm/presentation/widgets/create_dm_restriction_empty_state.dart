import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/dm/domain/create_dm_labels.dart';
import 'package:star_app/features/dm/domain/create_dm_restriction.dart';
import 'package:star_app/features/settings/presentation/sheets/claim_account_sheet.dart';
import 'package:star_app/features/settings/presentation/user_settings_modal.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class CreateDmRestrictionEmptyState extends ConsumerWidget {
  const CreateDmRestrictionEmptyState({required this.restriction, super.key});

  final CreateDmRestriction restriction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final bool isUnclaimed = restriction == CreateDmRestriction.unclaimed;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.layout.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            PhosphorIcon(
              isUnclaimed
                  ? PhosphorIconsFill.warningCircle
                  : PhosphorIconsFill.envelopeSimple,
              size: 40,
              color: context.colors.textTertiary,
            ),
            SizedBox(height: context.layout.s4),
            Text(
              createDmRestrictionTitle(l10n, restriction),
              textAlign: TextAlign.center,
              style: context.textStyles.username.copyWith(
                color: context.colors.textPrimary,
                fontSize: 16,
              ),
            ),
            SizedBox(height: context.layout.s2),
            Text(
              createDmRestrictionDescription(l10n, restriction),
              textAlign: TextAlign.center,
              style: context.textStyles.bodySmall.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            SizedBox(height: context.layout.s6),
            StarButton.primary(
              label: createDmRestrictionActionLabel(l10n, restriction),
              onPressed: () {
                if (isUnclaimed) {
                  unawaited(ClaimAccountSheet.show(context, ref));
                  return;
                }
                unawaited(
                  UserSettingsModal.show(context, openSecuritySection: true),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
