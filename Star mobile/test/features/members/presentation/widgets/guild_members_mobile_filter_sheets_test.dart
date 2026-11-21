import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/database/star_database.dart' as drift_db;
import 'package:star_app/features/guilds/domain/guild.dart';
import 'package:star_app/features/guilds/providers/guild_providers.dart';
import 'package:star_app/features/members/domain/guild_members_search_models.dart';
import 'package:star_app/features/members/presentation/widgets/guild_members_mobile_list_view.dart';
import 'package:star_app/features/members/providers/guild_members_search_provider.dart';
import 'package:star_app/features/members/providers/guild_roles_provider.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart';

import '../../../../helpers/pump_star_app.dart';
import '../../../../helpers/test_l10n.dart';

const String _guildId = '100';

class _FakeGuildMembersSearch extends GuildMembersSearch {
  @override
  GuildMembersSearchState build(String guildId) =>
      GuildMembersSearchState.initial().copyWith(initialLoadDone: true);

  @override
  void setRoleFilter(List<String> roleIds) {
    state = state.copyWith(roleFilter: roleIds);
  }

  @override
  void setJoinMethodFilter(GuildMembersJoinMethodFilter filter) {
    state = state.copyWith(joinMethodFilter: filter);
  }
}

drift_db.Role _role(String id, String name, int position) => drift_db.Role(
  id: id,
  guildId: _guildId,
  name: name,
  color: 0,
  position: position,
  hoist: false,
  mentionable: false,
  permissions: '0',
);

final Map<String, drift_db.Role> _roles = <String, drift_db.Role>{
  '1': _role('1', 'Moderators', 2),
  '2': _role('2', 'Helpers', 1),
};

Future<ProviderContainer> _pumpView(WidgetTester tester) async {
  await tester.pumpWidget(
    pumpStarApp(
      overrides: [
        guildMembersSearchProvider.overrideWith2(
          (String guildId) => _FakeGuildMembersSearch(),
        ),
        guildRolesByIdProvider.overrideWith(
          (Ref ref, String guildId) => Stream.value(_roles),
        ),
        guildByIdProvider.overrideWith(
          (Ref ref, String id) => Future<Guild?>.value(),
        ),
      ],
      child: const Scaffold(
        body: GuildMembersMobileListView(guildId: _guildId),
      ),
    ),
  );
  await pumpStarFrames(tester);
  return ProviderScope.containerOf(
    tester.element(find.byType(GuildMembersMobileListView)),
  );
}

Future<void> _openChip(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await pumpStarFrames(tester);
  await tester.tap(find.text(label));
  await pumpStarFrames(tester);
}

Finder _option(String label) => find.byWidgetPredicate(
  (Widget widget) =>
      widget is StarBottomSheetMenuItem && widget.label == label,
);

bool _isSelected(WidgetTester tester, String label) =>
    tester.widget<StarBottomSheetMenuItem>(_option(label)).isSelected;

void main() {
  testWidgets('join method sheet picks one method and dismisses', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _pumpView(tester);
    GuildMembersJoinMethodFilter filter() =>
        container.read(guildMembersSearchProvider(_guildId)).joinMethodFilter;

    await _openChip(tester, testL10n.guildMembersColumnJoinMethod);
    await tester.tap(_option(testL10n.guildMembersJoinSourceInvite));
    await pumpStarFrames(tester);

    expect(_option(testL10n.guildMembersJoinSourceInvite), findsNothing);
    expect(filter().sourceTypes, <JoinSourceType>[
      JoinSourceType.instantInvite,
    ]);

    await _openChip(tester, testL10n.guildMembersColumnJoinMethod);
    expect(_isSelected(tester, testL10n.guildMembersJoinSourceInvite), isTrue);
    await tester.tap(_option(testL10n.guildMembersJoinSourceVanityUrl));
    await pumpStarFrames(tester);

    expect(_option(testL10n.guildMembersJoinSourceVanityUrl), findsNothing);
    expect(filter().sourceTypes, <JoinSourceType>[JoinSourceType.vanityUrl]);
  });

  testWidgets('roles sheet stays open and reflects each toggle', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = await _pumpView(tester);
    List<String> roleFilter() =>
        container.read(guildMembersSearchProvider(_guildId)).roleFilter;

    await _openChip(tester, testL10n.guildMembersColumnRoles);

    await tester.tap(_option('Moderators'));
    await pumpStarFrames(tester);
    expect(_isSelected(tester, 'Moderators'), isTrue);

    await tester.tap(_option('Helpers'));
    await pumpStarFrames(tester);
    expect(roleFilter(), <String>['1', '2']);
    expect(_isSelected(tester, 'Moderators'), isTrue);
    expect(_isSelected(tester, 'Helpers'), isTrue);

    await tester.tap(_option('Moderators'));
    await pumpStarFrames(tester);
    expect(roleFilter(), <String>['2']);
    expect(_isSelected(tester, 'Moderators'), isFalse);
    expect(_isSelected(tester, 'Helpers'), isTrue);

    await tester.tap(_option(testL10n.guildMembersClearAll));
    await pumpStarFrames(tester);
    expect(roleFilter(), isEmpty);
    expect(_isSelected(tester, 'Helpers'), isFalse);
    expect(
      tester
          .widget<StarBottomSheetMenuItem>(
            _option(testL10n.guildMembersClearAll),
          )
          .enabled,
      isFalse,
    );
  });
}
