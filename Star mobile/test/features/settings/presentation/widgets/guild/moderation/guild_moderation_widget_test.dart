import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/guilds/domain/guild.dart';
import 'package:star_app/features/settings/domain/guild/guild_settings_details.dart';
import 'package:star_app/features/settings/presentation/widgets/guild/moderation/guild_moderation_widget.dart';
import 'package:star_app/features/settings/providers/guild/guild_settings_tab_providers.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/ui/radio_group/star_radio_group.dart';
import 'package:star_app/features/ui/settings/star_save_bar.dart';
import 'package:star_app/features/ui/switch_group/star_switch_group.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart';

import '../../../../../../helpers/core_test_provider_overrides.dart';
import '../../../../../../helpers/pump_star_app.dart';
import '../../../../../../helpers/test_l10n.dart';

const String _guildId = 'guild-1';
const String _ownerId = 'owner-1';

class _FixedUserSettings extends UserSettingsViewModel {
  @override
  UserSettingsViewState build() => const UserSettingsViewState(
    userId: 'member-1',
    username: 'member',
    displayName: 'member',
    discriminator: '0001',
    avatar: null,
    avatarColor: null,
    memberSince: null,
    status: 'online',
    messageDisplayCompact: false,
    developerMode: false,
    trustedDomains: <String>[],
  );
}

class _RecordingModerationActions extends GuildSettingsModerationActions {
  _RecordingModerationActions(this._requests);

  final List<GuildUpdateRequest> _requests;

  @override
  void build(String guildId) {}

  @override
  Future<void> updateModeration(GuildUpdateRequest body) async {
    _requests.add(body);
  }
}

GuildSettingsDetails _details({required int verificationLevel}) {
  return GuildSettingsDetails(
    guild: Guild(
      id: _guildId,
      name: 'Guild',
      ownerId: _ownerId,
      verificationLevel: verificationLevel,
    ),
  );
}

Future<List<GuildUpdateRequest>> _pump(
  WidgetTester tester, {
  required int verificationLevel,
}) async {
  final List<GuildUpdateRequest> requests = <GuildUpdateRequest>[];
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: coreTestProviderOverrides(
        extra: [
          currentUserIdProvider.overrideWithValue('member-1'),
          userSettingsViewModelProvider.overrideWith(_FixedUserSettings.new),
          guildSettingsModerationActionsProvider(
            _guildId,
          ).overrideWith(() => _RecordingModerationActions(requests)),
        ],
      ),
      child: MaterialApp(
        locale: kTestLocale,
        localizationsDelegates: starLocalizationsDelegates,
        supportedLocales: StarLocalizations.supportedLocales,
        theme: buildStarTheme(
          colorTheme: buildDarkColorTheme(),
          textTheme: StarTextTheme.fromColors(buildDarkColorTheme()),
          layoutTheme: StarLayoutTheme.scaled(),
        ),
        home: Scaffold(
          body: GuildModerationWidget(
            guildId: _guildId,
            details: _details(verificationLevel: verificationLevel),
          ),
        ),
      ),
    ),
  );
  await pumpStarFramesQuick(tester);
  return requests;
}

StarRadioGroup<int> _verificationGroup(WidgetTester tester) {
  return tester
      .widgetList<StarRadioGroup<int>>(
        find.byWidgetPredicate(
          (Widget widget) => widget is StarRadioGroup<int>,
        ),
      )
      .first;
}

void main() {
  testWidgets('offers the four supported verification levels', (
    WidgetTester tester,
  ) async {
    await _pump(tester, verificationLevel: 2);
    final StarRadioGroup<int> group = _verificationGroup(tester);
    expect(group.items.map((StarRadioItem<int> item) => item.value), <int>[
      0,
      1,
      2,
      3,
    ]);
    expect(group.items.map((StarRadioItem<int> item) => item.label), <String>[
      testL10n.guildSettingsVerificationNone,
      testL10n.guildSettingsVerificationLow,
      testL10n.guildSettingsVerificationMedium,
      testL10n.guildSettingsVerificationHigh,
    ]);
    expect(group.value, 2);
  });

  testWidgets('shows a retired level above high as high with nothing to save', (
    WidgetTester tester,
  ) async {
    await _pump(tester, verificationLevel: 4);
    expect(_verificationGroup(tester).value, 3);
    expect(
      tester.widget<StarSaveBar>(find.byType(StarSaveBar)).visible,
      isFalse,
    );
  });

  testWidgets('saves high for a guild stored with a retired level', (
    WidgetTester tester,
  ) async {
    final List<GuildUpdateRequest> requests = await _pump(
      tester,
      verificationLevel: 4,
    );
    await tester.tap(
      find.widgetWithText(
        StarSettingsSwitchItem,
        testL10n.guildSettingsModerationMatureToggle,
      ),
    );
    await pumpStarFramesQuick(tester);
    final StarSaveBar saveBar = tester.widget<StarSaveBar>(
      find.byType(StarSaveBar),
    );
    expect(saveBar.visible, isTrue);
    saveBar.onSave();
    await pumpStarFramesQuick(tester);
    expect(requests, hasLength(1));
    expect(requests.single.verificationLevel, GuildVerificationLevelInput.high);
    final Object? wire = jsonDecode(jsonEncode(requests.single));
    expect((wire! as Map<String, Object?>)['verification_level'], 3);
  });
}
