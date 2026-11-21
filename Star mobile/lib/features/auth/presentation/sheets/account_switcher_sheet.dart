import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/auth/domain/auth_failure.dart';
import 'package:star_app/features/auth/domain/stored_account.dart';
import 'package:star_app/features/auth/presentation/add_account_screen.dart';
import 'package:star_app/features/auth/presentation/widgets/account_row.dart';
import 'package:star_app/features/auth/presentation/widgets/instance_domain_icon.dart';
import 'package:star_app/features/auth/providers/account_manager_provider.dart';
import 'package:star_app/features/ui/avatar/star_avatar.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/desktop_surface/star_desktop_surface.dart';
import 'package:star_app/features/ui/modal/star_modal.dart';
import 'package:star_app/features/ui/selected_check/star_selected_check.dart';
import 'package:star_app/features/ui/tappable/star_tappable.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class AccountSwitcherSheet {
  AccountSwitcherSheet._();

  static Future<void> show(BuildContext context) async {
    await StarBottomSheet.show<void>(
      context,
      title: StarLocalizations.of(context).profileTabMenuSwitchAccounts,
      variant: StarBottomSheetVariant.menu,
      useRootNavigator: true,
      desktop: const StarDesktopPresentation(
        surface: StarDesktopSurface.modal,
      ),
      builder: (sheetContext, close) {
        return StarBottomSheetContent(
          child: AccountSwitcherSheetBody(onClose: close),
        );
      },
    );
  }
}

class AccountSwitcherSheetBody extends ConsumerWidget {
  const AccountSwitcherSheetBody({required this.onClose, super.key});

  final VoidCallback onClose;

  Future<void> _confirmSignOut(
    BuildContext context,
    WidgetRef ref,
    StoredAccount account, {
    required bool isCurrent,
  }) async {
    final StarLocalizations l10n = StarLocalizations.of(context);
    await StarConfirmModal.show(
      context,
      title: l10n.accountSignOutTitle(account.identifier),
      description: l10n.accountRemoveDescription,
      confirmLabel: l10n.signOut,
      isDanger: true,
      onConfirm: () {
        final AccountManager manager = ref.read(
          accountManagerProvider.notifier,
        );
        if (isCurrent) {
          unawaited(manager.signOut(account.userId));
        } else {
          unawaited(manager.removeAccount(account.userId));
        }
      },
    );
  }

  Future<void> _openAddAccount({StoredAccount? expiredAccount}) async {
    final BuildContext? rootContext = rootNavigatorKey.currentContext;
    if (rootContext == null || !rootContext.mounted) {
      return;
    }
    await Navigator.of(rootContext, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => AddAccountScreen(expiredAccount: expiredAccount),
      ),
    );
  }

  Future<void> _handleSelectAccount(
    WidgetRef ref,
    StoredAccount account,
    StarLocalizations l10n,
  ) async {
    final String? currentUserId = ref.read(currentUserIdProvider);
    if (account.userId == currentUserId) {
      onClose();
      return;
    }
    onClose();
    if (!account.isValid) {
      await _openAddAccount(expiredAccount: account);
      return;
    }
    try {
      await ref
          .read(accountManagerProvider.notifier)
          .switchToAccount(account.userId, ignoreIfPending: true);
    } on SessionExpiredFailure {
      await _openAddAccount(expiredAccount: account);
    } on Object catch (_) {
      ref
          .read(toastProvider.notifier)
          .show(
            StarToast(
              message: l10n.accountSwitchFailed,
              variant: StarToastVariant.danger,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<StoredAccount> accounts = ref
        .watch(accountManagerProvider)
        .accounts;
    final String? currentUserId = ref.watch(currentUserIdProvider);
    final StarLocalizations l10n = StarLocalizations.of(context);

    if (StarDesktopSurfaceScope.isMenu(context)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final StoredAccount account in accounts)
            _DesktopAccountMenuItem(
              account: account,
              isCurrent: account.userId == currentUserId,
              onTap: () => unawaited(_handleSelectAccount(ref, account, l10n)),
            ),
          const SizedBox(height: 8),
          Container(height: 1, color: context.colors.backgroundModifierAccent),
          const SizedBox(height: 8),
          StarDesktopMenuRow(
            label: l10n.accountManageTitle,
            leading: const PhosphorIcon(PhosphorIconsBold.gear, size: 16),
            onTap: () {
              final BuildContext? rootContext = rootNavigatorKey.currentContext;
              onClose();
              if (rootContext != null && rootContext.mounted) {
                unawaited(AccountSwitcherSheet.show(rootContext));
              }
            },
          ),
        ],
      );
    }

    return StarBottomSheetGroupColumn(
      children: [
        StarMenuGroup(
          children: [
            for (final StoredAccount account in accounts)
              _AccountSwitcherRow(
                account: account,
                isCurrent: account.userId == currentUserId,
                onTap: () =>
                    unawaited(_handleSelectAccount(ref, account, l10n)),
                onSignOut: () => unawaited(
                  _confirmSignOut(
                    context,
                    ref,
                    account,
                    isCurrent: account.userId == currentUserId,
                  ),
                ),
              ),
            _AddAccountRow(
              onTap: () {
                onClose();
                unawaited(_openAddAccount());
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _AccountSwitcherRow extends StatelessWidget {
  const _AccountSwitcherRow({
    required this.account,
    required this.isCurrent,
    required this.onTap,
    required this.onSignOut,
  });

  final StoredAccount account;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final StarLocalizations l10n = StarLocalizations.of(context);

    return StarTappable(
      onTap: onTap,
      selected: isCurrent,
      semanticLabel: '${account.identifier}, ${account.instanceDomain}',
      builder: (BuildContext context, Set<WidgetState> states) {
        final bool isPressed = states.contains(WidgetState.pressed);
        return ColoredBox(
          color: isPressed ? colors.listItemPressedBg : Colors.transparent,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 6, 10),
            child: Row(
              children: [
                StarAvatar.user(
                  userId: account.userId,
                  imageUrl: account.avatarUrl(),
                  fallbackText: account.displayName,
                  showStatus: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        account.identifier,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyles.username.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          InstanceDomainIcon(
                            isOfficial: account.isOfficialInstance,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              account.isValid
                                  ? account.instanceDomain
                                  : '${account.instanceDomain} · ${l10n.accountExpired}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textStyles.timestamp.copyWith(
                                color: account.isValid
                                    ? colors.textTertiary
                                    : colors.textDanger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: 12),
                  const StarSelectedCheck(),
                ],
                const SizedBox(width: 4),
                AccountOverflowButton(onSignOut: onSignOut),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AddAccountRow extends StatelessWidget {
  const _AddAccountRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final String label = StarLocalizations.of(context).accountAdd;

    return StarTappable(
      onTap: onTap,
      semanticLabel: label,
      excludeChildSemantics: true,
      builder: (BuildContext context, Set<WidgetState> states) {
        final bool isPressed = states.contains(WidgetState.pressed);
        return ColoredBox(
          color: isPressed ? colors.listItemPressedBg : Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.backgroundModifierAccent,
                    ),
                    child: Center(
                      child: PhosphorIcon(
                        PhosphorIconsBold.plus,
                        size: 18,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: context.textStyles.username.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DesktopAccountMenuItem extends StatelessWidget {
  const _DesktopAccountMenuItem({
    required this.account,
    required this.isCurrent,
    required this.onTap,
  });

  final StoredAccount account;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final StarLocalizations l10n = StarLocalizations.of(context);
    final String? meta = !account.isValid
        ? l10n.accountExpired
        : isCurrent
        ? l10n.accountActive
        : null;
    return StarTappable(
      onTap: onTap,
      selected: isCurrent,
      semanticLabel: meta == null
          ? account.identifier
          : '${account.identifier}. $meta',
      excludeChildSemantics: true,
      builder: (BuildContext context, Set<WidgetState> states) {
        final bool highlighted =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused);
        return Container(
          constraints: const BoxConstraints(
            minHeight: kStarDesktopMenuRowMinHeight,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: highlighted
                ? colors.surfaceInteractiveHoverBg
                : Colors.transparent,
            borderRadius: context.layout.radiusMd,
          ),
          child: Row(
            children: <Widget>[
              StarAvatar.user(
                imageUrl: account.avatarUrl(),
                fallbackText: account.displayName,
                userId: account.userId,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 2,
                  children: <Widget>[
                    Text(
                      account.identifier,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: starDesktopMenuLabelStyle(
                        context,
                      ).copyWith(color: colors.textPrimary, height: 16 / 13),
                    ),
                    if (meta != null)
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.timestamp.copyWith(
                          color: account.isValid
                              ? colors.statusOnline
                              : colors.statusDanger,
                          fontSize: 11,
                          height: 14 / 11,
                        ),
                      ),
                  ],
                ),
              ),
              if (isCurrent) ...<Widget>[
                const SizedBox(width: 10),
                const StarSelectedCheck(size: 20),
              ],
            ],
          ),
        );
      },
    );
  }
}
