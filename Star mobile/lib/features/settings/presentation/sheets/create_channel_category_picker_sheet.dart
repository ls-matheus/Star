import 'package:star_app/features/channels/presentation/sheets/create_category_sheet.dart';
import 'package:star_app/features/channels/presentation/sheets/create_channel_sheet.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_dart/export.dart';

class CreateChannelCategoryPickerSheet {
  CreateChannelCategoryPickerSheet._();

  static Future<void> show(
    BuildContext context, {
    String? parentId,
    String? guildId,
    Future<void> Function(ChannelCreateRequest request)? onCreateChannel,
    Future<void> Function(String name)? onCreateCategory,
  }) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return StarBottomSheet.show<void>(
      context,
      title: l10n.guildMenuSettingsChannels,
      variant: StarBottomSheetVariant.menu,
      useRootNavigator: true,
      builder: (BuildContext sheetContext, VoidCallback close) {
        return StarBottomSheetContent(
          scrollable: false,
          child: StarBottomSheetGroupColumn(
            children: <Widget>[
              StarMenuGroup(
                children: <Widget>[
                  StarBottomSheetMenuItem(
                    label: l10n.guildNavbarCreateChannel,
                    icon: PhosphorIconsFill.plusCircle,
                    onTap: () async {
                      close();
                      if (!context.mounted) {
                        return;
                      }
                      final ChannelCreateRequest? request =
                          await CreateChannelSheet.show(
                            context,
                            parentId: parentId,
                            guildId: guildId,
                          );
                      if (request != null && context.mounted) {
                        await onCreateChannel?.call(request);
                      }
                    },
                  ),
                  StarBottomSheetMenuItem(
                    label: l10n.guildNavbarCreateCategory,
                    icon: PhosphorIconsFill.folderPlus,
                    onTap: () async {
                      close();
                      if (!context.mounted) {
                        return;
                      }
                      final String? name = await CreateCategorySheet.show(
                        context,
                      );
                      if (name != null && name.isNotEmpty && context.mounted) {
                        await onCreateCategory?.call(name);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
