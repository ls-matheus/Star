import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/material_ui.dart';

bool resolveShellPopupUseRootNavigator(BuildContext context) {
  return !isMobileLayout(context) ||
      isPinnedSidebarLayout(context) ||
      isPinnedSidebarSplitAtHinge(context);
}
