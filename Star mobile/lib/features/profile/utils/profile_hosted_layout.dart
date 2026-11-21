import 'package:star_app/features/shell/hosted_ui/hosted_ui_background_bleed.dart';
import 'package:star_app/features/shell/hosted_ui/iphone_duo_hosted_ui.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/material_ui.dart';

EdgeInsets profileHostedSideContentInsets(BuildContext context) {
  if (StarBottomSheet.isInSheet(context)) {
    return EdgeInsets.zero;
  }
  return hostedUiSideInsets(context);
}

bool profileHostedBannerBleedsIntoSideStrip(BuildContext context) {
  if (StarBottomSheet.isInSheet(context)) {
    return false;
  }
  final EdgeInsets bleed = hostedUiBackgroundBleedInsets(context);
  return bleed.left > 0 || bleed.right > 0;
}
