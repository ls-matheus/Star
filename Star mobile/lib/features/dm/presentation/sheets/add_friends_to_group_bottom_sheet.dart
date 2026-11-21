import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/dm/domain/dm_conversation.dart';
import 'package:star_app/features/dm/presentation/widgets/add_friends_to_group_body.dart';
import 'package:star_app/features/dm/providers/add_friends_to_group_controller.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class AddFriendsToGroupBottomSheet {
  AddFriendsToGroupBottomSheet._();

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required DmConversation dm,
  }) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return StarBottomSheet.showScrollable<void>(
      context,
      title: l10n.createDmSelectFriends,
      useRootNavigator: true,
      minChildSize: 0.55,
      builder:
          (
            BuildContext sheetContext,
            ScrollController scrollController,
            VoidCallback close,
          ) {
            return _AddFriendsToGroupBottomSheetBody(
              dm: dm,
              scrollController: scrollController,
            );
          },
    );
  }
}

class _AddFriendsToGroupBottomSheetBody extends ConsumerStatefulWidget {
  const _AddFriendsToGroupBottomSheetBody({
    required this.dm,
    required this.scrollController,
  });

  final DmConversation dm;
  final ScrollController scrollController;

  @override
  ConsumerState<_AddFriendsToGroupBottomSheetBody> createState() =>
      _AddFriendsToGroupBottomSheetBodyState();
}

class _AddFriendsToGroupBottomSheetBodyState
    extends ConsumerState<_AddFriendsToGroupBottomSheetBody> {
  AddFriendsToGroupController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) {
      return;
    }
    final AddFriendsToGroupController controller = AddFriendsToGroupController(
      container: ref.container,
      channelId: widget.dm.id,
      dm: widget.dm,
    )..addListener(_handleControllerChanged);
    _controller = controller;
  }

  @override
  void dispose() {
    _controller
      ?..removeListener(_handleControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final AddFriendsToGroupController? controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.layout.s4),
      child: AddFriendsToGroupBody(
        controller: controller,
        scrollController: widget.scrollController,
      ),
    );
  }
}
