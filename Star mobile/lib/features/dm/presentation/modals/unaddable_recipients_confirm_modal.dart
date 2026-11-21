import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/dm/domain/create_dm_labels.dart';
import 'package:star_app/features/dm/utils/create_dm_api_errors.dart';
import 'package:star_app/features/friends/providers/friend_providers.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

Future<void> showUnaddableRecipientsConfirmModal(
  BuildContext context, {
  required List<UnaddableRecipient> unaddableRecipients,
  required int addableCount,
  required Future<void> Function() onConfirm,
}) {
  final StarLocalizations l10n = StarLocalizations.of(context);
  return StarModal.show<void>(
    context,
    title: l10n.createDmSomeUsersCantBeAdded,
    centered: true,
    builder: (BuildContext dialogContext, VoidCallback close) {
      return Consumer(
        builder: (BuildContext context, WidgetRef modalRef, Widget? _) {
          final friends = modalRef.watch(friendsListProvider).value ?? const [];
          final Map<String, String> names = <String, String>{
            for (final friend in friends) friend.id: friend.displayName,
          };
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.createDmUnaddableIntro,
                style: dialogContext.textStyles.bodySmall.copyWith(
                  color: dialogContext.colors.textSecondary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: dialogContext.layout.s3),
              ...unaddableRecipients.map((UnaddableRecipient entry) {
                final String name = names[entry.userId] ?? entry.userId;
                return Padding(
                  padding: EdgeInsets.only(bottom: dialogContext.layout.s1),
                  child: Text(
                    '$name: ${unaddableRecipientReasonLabel(l10n, entry.reason)}',
                    style: dialogContext.textStyles.bodySmall.copyWith(
                      color: dialogContext.colors.textPrimary,
                    ),
                  ),
                );
              }),
              SizedBox(height: dialogContext.layout.s3),
              Text(
                addableCount > 0
                    ? l10n.createDmUnaddableProceed(addableCount)
                    : l10n.createDmUnaddableNoneRemaining,
                style: dialogContext.textStyles.bodySmall.copyWith(
                  color: dialogContext.colors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          );
        },
      );
    },
    actionsBuilder: (void Function([void]) pop) {
      if (addableCount == 0) {
        return <Widget>[
          StarButton.secondary(label: l10n.uiClose, onPressed: () => pop()),
        ];
      }
      return <Widget>[
        StarButton.primary(
          label: l10n.createDmCreateWithoutThem,
          onPressed: () async {
            await onConfirm();
            pop();
          },
        ),
        const SizedBox(height: 8),
        StarButton.secondary(label: l10n.cancel, onPressed: () => pop()),
      ];
    },
  );
}
