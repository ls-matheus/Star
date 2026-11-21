import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/profile/presentation/widgets/user_profile_view.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/shell/hosted_ui/hosted_ui_background_bleed.dart';
import 'package:star_app/material_ui.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UserSettingsViewState state = ref.watch(
      userSettingsViewModelProvider,
    );
    final Color background = context.colors.backgroundPrimary;
    return Scaffold(
      backgroundColor: background,
      body: HostedUiBackgroundBleed(
        color: background,
        child: UserProfileView(
          userId: state.userId,
          autoFocusNote: false,
          scrollController: _scrollController,
          useCurrentUserCache: true,
        ),
      ),
    );
  }
}
