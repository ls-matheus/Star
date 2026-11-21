import 'package:star_app/core/synced_preferences/fields/accessibility_synced_field.dart';
import 'package:star_app/features/settings/providers/preferences/advanced_preferences_provider.dart';
import 'package:star_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:star_app/features/voice/tts/tts_text_formatter.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:test/test.dart';

void main() {
  final StarLocalizations l10n = lookupStarLocalizations(
    const Locale('en'),
  );

  group('formatMessageContentForTts', () {
    test('strips markdown and substitutes mentions', () {
      final String result = formatMessageContentForTts(
        content: '**hello** <@123> ||secret|| `code`',
        l10n: l10n,
      );
      expect(result, contains('hello'));
      expect(result, contains(l10n.ttsSubstitutionUnknownUser));
      expect(result, contains(l10n.ttsSubstitutionSpoiler));
      expect(result, contains('code'));
    });
  });

  group('AccessibilitySyncedField tts prefs', () {
    test('roundtrips enableTtsCommand and ttsRate', () {
      const AccessibilityLocalState state = AccessibilityLocalState(
        hideKeyboardHints: false,
        channelTypingIndicatorMode: ChannelTypingIndicatorMode.avatars,
        showSelectedChannelTypingIndicator: false,
        showFadedUnreadOnMutedChannels: false,
        dmMessagePreviewMode: DmMessagePreviewMode.all,
        showFavorites: true,
        messageGroupSpacing: 16,
        compactMessageGroupSpacing: 0,
        saturationFactor: 1,
        customThemeCss: null,
        advanced: AdvancedAccessibilityLocalState(
          enableTextSelection: false,
          voiceChannelJoinRequiresDoubleClick: false,
          confirmBeforeJoiningVoiceChannels: false,
          showGifIndicator: true,
          showAttachmentExpiryIndicator: true,
          showMessageActionBar: true,
          showMessageActionBarQuickReactions: true,
          showMessageActionBarShiftExpand: true,
          showMessageActionBarOnlyMoreButton: false,
          showGifButton: true,
          showMemesButton: true,
          showStickersButton: true,
          showEmojiButton: true,
          showMessageSendButton: false,
          scrollToBottomOnMessageSend: true,
        ),
        enableTtsCommand: false,
        ttsRate: 1.5,
      );

      final roundtripped = AccessibilitySyncedField.fromProto(
        AccessibilitySyncedField.toProto(state),
      );

      expect(roundtripped.enableTtsCommand, isFalse);
      expect(roundtripped.ttsRate, 1.5);
    });
  });
}
