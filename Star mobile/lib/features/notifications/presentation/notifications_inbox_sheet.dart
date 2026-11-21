import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/notifications/presentation/widgets/notifications_mentions_body.dart';
import 'package:star_app/features/notifications/presentation/widgets/notifications_tab_bar.dart';
import 'package:star_app/features/notifications/presentation/widgets/notifications_unreads_body.dart';
import 'package:star_app/features/notifications/providers/notifications_providers.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/desktop_surface/star_desktop_surface.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class NotificationsInboxSheet {
  NotificationsInboxSheet._();

  static Future<void> show(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return StarBottomSheet.showScrollable<void>(
      context,
      title: l10n.notificationsPageTitle,
      useRootNavigator: true,
      minChildSize: 0.55,
      desktop: const StarDesktopPresentation(
        surface: StarDesktopSurface.popout,
        width: 480,
        placement: StarDesktopPlacement.rightStart,
      ),
      builder:
          (
            BuildContext sheetContext,
            ScrollController scrollController,
            VoidCallback close,
          ) {
            return _NotificationsInboxSheetBody(
              scrollController: scrollController,
            );
          },
    );
  }
}

class _NotificationsInboxSheetBody extends ConsumerStatefulWidget {
  const _NotificationsInboxSheetBody({required this.scrollController});

  final ScrollController scrollController;

  @override
  ConsumerState<_NotificationsInboxSheetBody> createState() =>
      _NotificationsInboxSheetBodyState();
}

class _NotificationsInboxSheetBodyState
    extends ConsumerState<_NotificationsInboxSheetBody> {
  late final PageController _pages = PageController(
    initialPage: ref.read(notificationsInboxSegmentProvider).index,
  );
  late final ValueNotifier<double> _position = ValueNotifier<double>(
    _pages.initialPage.toDouble(),
  );

  @override
  void initState() {
    super.initState();
    _pages.addListener(() {
      _position.value = _pages.page ?? _position.value;
    });
    ref.listenManual<NotificationsInboxTab>(notificationsInboxSegmentProvider, (
      _,
      NotificationsInboxTab next,
    ) {
      if (_pages.hasClients && _pages.page?.round() != next.index) {
        _pages.animateToPage(
          next.index,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    _position.dispose();
    super.dispose();
  }

  void _select(int index) {
    ref
        .read(notificationsInboxSegmentProvider.notifier)
        .select(NotificationsInboxTab.values[index]);
  }

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(bottom: context.layout.s3),
          child: NotificationsTabBar(
            labels: <String>[
              l10n.notificationsFilterUnreads,
              l10n.notificationsFilterMentions,
            ],
            position: _position,
            onSelected: _select,
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pages,
            onPageChanged: _select,
            children: <Widget>[
              NotificationsUnreadsBody(
                selected:
                    ref.watch(notificationsInboxSegmentProvider) ==
                    NotificationsInboxTab.unreads,
              ),
              NotificationsMentionsBody(
                selected:
                    ref.watch(notificationsInboxSegmentProvider) ==
                    NotificationsInboxTab.mentions,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
