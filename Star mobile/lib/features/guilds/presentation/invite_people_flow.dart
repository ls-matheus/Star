import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/guilds/domain/invite_people_recipient.dart';
import 'package:star_app/features/guilds/presentation/widgets/invite_people_content.dart';
import 'package:star_app/features/guilds/utils/invites/invite_people_actions.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class InvitePeopleFlow {
  InvitePeopleFlow._();

  static Future<void> show(
    BuildContext context, {
    required String communityName,
    required InvitePeopleCreateFn createInvite,
    required Future<List<InvitePeopleRecipient>> Function() getRecipients,
    required InvitePeopleSendFn sendInvite,
    String? vanityUrl,
  }) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final String title = l10n.guildNavbarInviteFriendsTo(communityName);
    if (isMobileLayout(context)) {
      return StarBottomSheet.showScrollable<void>(
        context,
        title: title,
        useRootNavigator: true,
        bottomGap: false,
        minChildSize: 0.5,
        builder:
            (
              BuildContext sheetContext,
              ScrollController scrollController,
              VoidCallback close,
            ) {
              return _content(
                host: sheetContext,
                createInvite: createInvite,
                getRecipients: getRecipients,
                sendInvite: sendInvite,
                vanityUrl: vanityUrl,
                scrollController: scrollController,
              );
            },
      );
    }
    return StarModal.show<void>(
      context,
      useRootNavigator: true,
      title: title,
      builder: (BuildContext dialogContext, VoidCallback close) {
        return SizedBox(
          height: 480,
          child: _content(
            host: dialogContext,
            createInvite: createInvite,
            getRecipients: getRecipients,
            sendInvite: sendInvite,
            vanityUrl: vanityUrl,
          ),
        );
      },
    );
  }

  static InvitePeopleContent _content({
    required BuildContext host,
    required InvitePeopleCreateFn createInvite,
    required Future<List<InvitePeopleRecipient>> Function() getRecipients,
    required InvitePeopleSendFn sendInvite,
    String? vanityUrl,
    ScrollController? scrollController,
  }) {
    return InvitePeopleContent(
      createInvite: createInvite,
      getRecipients: getRecipients,
      sendInvite: sendInvite,
      vanityUrl: vanityUrl,
      fill: true,
      scrollController: scrollController,
      onEditLink: () => showInviteLinkSettings(host),
    );
  }

  static Future<({int maxAge, int maxUses, bool temporary})?>
  showInviteLinkSettings(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    var maxAge = kDefaultInviteMaxAgeSeconds;
    var maxUses = 0;
    var temporary = false;

    Widget form() {
      return StatefulBuilder(
        builder:
            (BuildContext context, void Function(void Function()) setState) {
              final layout = context.layout;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: layout.s4,
                children: <Widget>[
                  StarSelect<int>(
                    label: l10n.guildNavbarExpireAfter,
                    value: maxAge,
                    stretch: true,
                    enableSearch: false,
                    items: <StarSelectItem<int>>[
                      StarSelectItem(value: 0, label: l10n.guildNavbarNever),
                      StarSelectItem(
                        value: 1800,
                        label: l10n.guildNavbarDuration30Minutes,
                      ),
                      StarSelectItem(
                        value: 3600,
                        label: l10n.guildNavbarDuration1Hour,
                      ),
                      StarSelectItem(
                        value: 21600,
                        label: l10n.guildNavbarDuration6Hours,
                      ),
                      StarSelectItem(
                        value: 43200,
                        label: l10n.guildNavbarDuration12Hours,
                      ),
                      StarSelectItem(
                        value: 86400,
                        label: l10n.guildNavbarDuration1Day,
                      ),
                      StarSelectItem(
                        value: kDefaultInviteMaxAgeSeconds,
                        label: l10n.guildNavbarDuration7Days,
                      ),
                    ],
                    onChanged: (int v) => setState(() => maxAge = v),
                  ),
                  StarSelect<int>(
                    label: l10n.guildNavbarMaxUses,
                    value: maxUses,
                    stretch: true,
                    enableSearch: false,
                    items: <StarSelectItem<int>>[
                      StarSelectItem(
                        value: 0,
                        label: l10n.guildNavbarNoLimit,
                      ),
                      StarSelectItem(value: 1, label: l10n.guildNavbarOneUse),
                      StarSelectItem(
                        value: 5,
                        label: l10n.guildNavbarUses(5),
                      ),
                      StarSelectItem(
                        value: 10,
                        label: l10n.guildNavbarUses(10),
                      ),
                      StarSelectItem(
                        value: 25,
                        label: l10n.guildNavbarUses(25),
                      ),
                      StarSelectItem(
                        value: 50,
                        label: l10n.guildNavbarUses(50),
                      ),
                      StarSelectItem(
                        value: 100,
                        label: l10n.guildNavbarUses(100),
                      ),
                    ],
                    onChanged: (int v) => setState(() => maxUses = v),
                  ),
                  StarToggleSwitch(
                    value: temporary,
                    onChanged: (bool v) => setState(() => temporary = v),
                    label: l10n.guildNavbarGrantTemporaryMembership,
                    description: l10n.guildNavbarTemporaryMembershipDescription,
                  ),
                ],
              );
            },
      );
    }

    if (isMobileLayout(context)) {
      return StarBottomSheet.show<
        ({int maxAge, int maxUses, bool temporary})
      >(
        context,
        useRootNavigator: true,
        title: l10n.guildNavbarInviteLinkSettings,
        builder: (BuildContext sheetContext, VoidCallback close) {
          final layout = sheetContext.layout;
          return Padding(
            padding: EdgeInsets.fromLTRB(layout.s4, 0, layout.s4, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                form(),
                SizedBox(height: layout.s4),
                StarButton.primary(
                  onPressed: () => Navigator.of(sheetContext).pop((
                    maxAge: maxAge,
                    maxUses: maxUses,
                    temporary: temporary,
                  )),
                  label: l10n.guildNavbarCreateNewLink,
                ),
                SizedBox(height: layout.s2),
                StarButton.secondary(onPressed: close, label: l10n.cancel),
              ],
            ),
          );
        },
      );
    }

    return StarModal.show<({int maxAge, int maxUses, bool temporary})>(
      context,
      useRootNavigator: true,
      title: l10n.guildNavbarInviteLinkSettings,
      builder: (BuildContext dialogContext, VoidCallback close) => form(),
      actionsBuilder:
          (
            void Function([({int maxAge, int maxUses, bool temporary})? result])
            pop,
          ) => <Widget>[
            StarButton.primary(
              onPressed: () =>
                  pop((maxAge: maxAge, maxUses: maxUses, temporary: temporary)),
              label: l10n.guildNavbarCreateNewLink,
            ),
            const SizedBox(height: 8),
            StarButton.secondary(onPressed: () => pop(), label: l10n.cancel),
          ],
    );
  }
}
