// Root ProviderScope built by a helper; the lint only exempts a
// ProviderScope written inline in pumpWidget.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/limits/instance_limit_provider.dart';
import 'package:star_app/core/limits/limit_key.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/settings/presentation/widgets/user_audio_and_video.dart';
import 'package:star_app/features/settings/providers/preferences/voice_prompts_preferences_provider.dart';
import 'package:star_app/features/settings/providers/preferences/voice_settings_provider.dart';
import 'package:star_app/features/ui/slider/star_slider.dart';
import 'package:star_app/features/voice/providers/voice_media_devices_provider.dart';
import 'package:star_app/features/voice/providers/voice_session_provider.dart';
import 'package:star_app/features/voice/providers/voice_session_state.dart';
import 'package:star_app/features/voice/services/voice_settings_applicator.dart';
import 'package:star_app/features/voice/utils/screen_share/screen_share_presets.dart';
import 'package:star_app/material_ui.dart';

import '../../helpers/test_l10n.dart';

Widget _wrap(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    overrides: [
      instanceFeatureEnabledProvider(
        LimitKeys.featureHigherVideoQuality,
      ).overrideWith((Ref ref) => false),
      voiceSettingsApplicatorProvider.overrideWithValue(
        const VoiceSettingsApplicator(
          noiseFilterSupported: false,
          videoQualityCaps: VideoQualityCaps.base,
          meshPhoneCap: false,
        ),
      ),
      voiceMediaDevicesProvider.overrideWith(_FakeVoiceMediaDevices.new),
      voiceSettingsProvider.overrideWith(VoiceSettings.new),
      voicePromptsPreferencesProvider.overrideWith(VoicePromptsPreferences.new),
      voiceSessionProvider.overrideWith(_FakeVoiceSession.new),
    ],
    child: MaterialApp(
      locale: kTestLocale,
      localizationsDelegates: starLocalizationsDelegates,
      supportedLocales: StarLocalizations.supportedLocales,
      theme: buildStarTheme(
        colorTheme: colorTheme,
        textTheme: StarTextTheme.fromColors(colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
      ),
      home: Scaffold(body: child),
    ),
  );
}

class _FakeVoiceMediaDevices extends VoiceMediaDevices {
  @override
  VoiceMediaDevicesState build() => const VoiceMediaDevicesState();
}

class _FakeVoiceSession extends VoiceSession {
  @override
  VoiceSessionState build() => const VoiceSessionState();
}

void main() {
  testWidgets('input volume slider commits a lower value', (tester) async {
    await tester.pumpWidget(_wrap(const UserAudioAndVideo()));
    await tester.pumpAndSettle();

    final Finder inputVolumeLabel = find.text('Input volume');
    await tester.scrollUntilVisible(
      inputVolumeLabel,
      48,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final Finder slider = find.byType(StarSlider).first;

    await tester.drag(slider, const Offset(-80, 0));
    await tester.pumpAndSettle();

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(UserAudioAndVideo)),
    );
    expect(container.read(voiceSettingsProvider).inputVolume, lessThan(100));
  });

  testWidgets('renders audio and video settings sections', (tester) async {
    await tester.pumpWidget(_wrap(const UserAudioAndVideo()));
    await tester.pumpAndSettle();
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);
    expect(find.text('In-call behavior'), findsOneWidget);
    expect(find.text('Focused voice'), findsOneWidget);
    expect(find.text('Mirror camera'), findsOneWidget);
  });
}
