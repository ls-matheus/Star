import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/shell/hosted_ui/iphone_duo_hosted_ui.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/material_ui.dart';

Color channelChatShellBackgroundForLayout({
  required StarColorTheme colors,
  required bool mobileLayout,
  required bool duoHostedUi,
}) {
  if (mobileLayout && !duoHostedUi) {
    return colors.chatInputBackground;
  }
  return colors.chatBackground;
}

Color channelChatShellBackgroundColor(BuildContext context) {
  return channelChatShellBackgroundForLayout(
    colors: context.colors,
    mobileLayout: isMobileLayout(context),
    duoHostedUi: usesIphoneDuoHostedUi(context),
  );
}

Color channelChatHostedUiBleedColor(BuildContext context) {
  if (hasIphoneDuoSideStrip(context)) {
    return context.colors.chatBackground;
  }
  return channelChatShellBackgroundColor(context);
}
