import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/media/star_media_url.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/friends/domain/friend.dart';
import 'package:star_app/features/friends/providers/friend_providers.dart';
import 'package:star_app/features/profile/presentation/user_profile_sheet.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/utils/api_error_presentation.dart';

class FriendRequestSheetItem extends ConsumerWidget {
  const FriendRequestSheetItem({required this.friend, super.key});

  final Friend friend;

  bool get _isIncoming => friend.friendStatus == FriendStatus.pendingIncoming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = StarLocalizations.of(context);
    final statusText = _isIncoming
        ? l10n.addFriendIncomingStatus
        : l10n.addFriendOutgoingStatus;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.layout.s4,
        vertical: context.layout.s3,
      ),
      child: Row(
        children: [
          StarAvatar.user(
            fallbackText: friend.displayName,
            userId: friend.id,
            imageUrl: StarMediaUrl.userAvatar(
              userId: friend.id,
              hash: friend.avatar,
              animated: true,
            ),
            avatarColor: friend.avatarColor,
            status: friend.status,
          ),
          SizedBox(width: context.layout.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.displayName,
                  style: context.textStyles.channelName,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: context.textStyles.bodySmall.copyWith(
                    color: context.colors.textTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          StarButton.circleAlt(
            icon: PhosphorIconsBold.dotsThreeVertical,
            size: StarButtonSize.compact,
            semanticLabel: l10n.uiMoreActions,
            onPressed: () => unawaited(_showMenu(context, ref)),
          ),
        ],
      ),
    );
  }

  Future<void> _showMenu(BuildContext context, WidgetRef ref) async {
    final l10n = StarLocalizations.of(context);
    await StarBottomSheet.show<void>(
      context,
      variant: StarBottomSheetVariant.menu,
      builder: (sheetContext, close) {
        final groups = <Widget>[
          StarMenuGroup(
            children: [
              StarBottomSheetMenuItem(
                label: l10n.addFriendViewProfile,
                icon: PhosphorIconsFill.user,
                onTap: () {
                  close();
                  unawaited(
                    StarUserProfileSheet.show(context, userId: friend.id),
                  );
                },
              ),
            ],
          ),
          if (_isIncoming)
            StarMenuGroup(
              children: [
                StarBottomSheetMenuItem(
                  label: l10n.addFriendAccept,
                  icon: PhosphorIconsBold.check,
                  onTap: () {
                    close();
                    unawaited(_confirmAccept(context, ref));
                  },
                ),
                StarBottomSheetMenuItem(
                  label: l10n.addFriendIgnore,
                  icon: PhosphorIconsBold.x,
                  isDanger: true,
                  onTap: () {
                    close();
                    unawaited(_confirmIgnore(context, ref));
                  },
                ),
              ],
            )
          else
            StarMenuGroup(
              children: [
                StarBottomSheetMenuItem(
                  label: l10n.addFriendCancelRequest,
                  icon: PhosphorIconsBold.x,
                  isDanger: true,
                  onTap: () {
                    close();
                    unawaited(_cancelRequest(ref));
                  },
                ),
              ],
            ),
        ];
        return StarBottomSheetContent(
          scrollable: false,
          child: StarBottomSheetGroupColumn(children: groups),
        );
      },
    );
  }

  Future<void> _confirmAccept(BuildContext context, WidgetRef ref) async {
    final l10n = StarLocalizations.of(context);
    await StarConfirmModal.show(
      context,
      title: l10n.addFriendAcceptTitle,
      description: l10n.addFriendAcceptConfirmDescription(friend.username),
      confirmLabel: l10n.addFriendAccept,
      onConfirm: () => unawaited(_acceptRequest(ref)),
    );
  }

  Future<void> _confirmIgnore(BuildContext context, WidgetRef ref) async {
    final l10n = StarLocalizations.of(context);
    await StarConfirmModal.show(
      context,
      title: l10n.addFriendIgnoreTitle,
      description: l10n.addFriendIgnoreConfirmDescription(friend.displayName),
      confirmLabel: l10n.addFriendIgnore,
      isDanger: true,
      onConfirm: () => unawaited(_cancelRequest(ref)),
    );
  }

  Future<void> _acceptRequest(WidgetRef ref) async {
    await _runRelationshipAction(
      ref,
      ApiErrorAction.acceptFriendRequest,
      () => ref.read(friendRepositoryProvider).acceptFriendRequest(friend.id),
    );
  }

  Future<void> _cancelRequest(WidgetRef ref) async {
    await _runRelationshipAction(
      ref,
      _isIncoming
          ? ApiErrorAction.ignoreFriendRequest
          : ApiErrorAction.cancelFriendRequest,
      () => ref.read(friendRepositoryProvider).removeRelationship(friend.id),
    );
  }

  Future<void> _runRelationshipAction(
    WidgetRef ref,
    ApiErrorAction errorAction,
    Future<void> Function() call,
  ) async {
    try {
      await call();
    } on Object catch (e) {
      if (!ref.context.mounted) {
        return;
      }
      await showApiError(ref.context, errorAction, e);
    }
  }
}
