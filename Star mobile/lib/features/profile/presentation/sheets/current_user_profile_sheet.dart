import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/profile/presentation/widgets/user_profile_view.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/material_ui.dart';

class CurrentUserProfileSheet {
  CurrentUserProfileSheet._();

  static Future<void> show(BuildContext context, WidgetRef ref) {
    final String userId = ref.read(userSettingsViewModelProvider).userId;
    return StarBottomSheet.showScrollable<void>(
      context,
      useRootNavigator: true,
      minChildSize: 0.55,
      builder:
          (
            BuildContext _,
            ScrollController scrollController,
            VoidCallback close,
          ) {
            return UserProfileView(
              userId: userId,
              autoFocusNote: false,
              scrollController: scrollController,
              useCurrentUserCache: true,
            );
          },
    );
  }
}
