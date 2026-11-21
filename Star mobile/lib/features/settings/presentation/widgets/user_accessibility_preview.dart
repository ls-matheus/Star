import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/media/star_media_url.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/accessibility/providers/effective_motion_preferences_provider.dart';
import 'package:star_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/markdown/star_markdown_adapter.dart';
import 'package:star_app/shared/markdown/native_markdown_parser.dart';
import 'package:star_markdown/star_markdown.dart';

const String kAccessibilityLinkPreviewExampleUrl = 'https://star.invalid';
const Color _kPreviewUsernameColor = Color(0xFFE91E63);

class UserAccessibilityPreview extends ConsumerWidget {
  const UserAccessibilityPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = StarLocalizations.of(context);
    final colors = context.colors;
    final appearance = ref.watch(appearancePreferencesProvider);
    final userSettings = ref.watch(userSettingsViewModelProvider);
    final String authorName = userSettings.displayName.trim().isEmpty
        ? l10n.accessibilityPreviewUserName
        : userSettings.displayName;
    final String message = l10n.accessibilityPreviewLinksMessage(
      kAccessibilityLinkPreviewExampleUrl,
    );
    final String? avatarUrl = StarMediaUrl.userAvatar(
      userId: userSettings.userId,
      hash: userSettings.avatar,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.backgroundModifierAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StarButton.primary(
                label: l10n.accessibilityPreviewButtonLabel,
                size: StarButtonSize.small,
                fitContent: true,
                onPressed: () {},
              ),
              const SizedBox(width: 12),
              const StarAvatar.user(
                userId: '100',
                fallbackText: 'A',
                status: 'online',
                size: 32,
              ),
              const SizedBox(width: 12),
              const StarAvatar.user(
                userId: '101',
                fallbackText: 'B',
                status: 'dnd',
                size: 32,
              ),
              const SizedBox(width: 12),
              const StarAvatar.user(
                userId: '102',
                fallbackText: 'C',
                status: 'idle',
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StarAvatar.user(
                userId: userSettings.userId,
                fallbackText: authorName,
                imageUrl: avatarUrl,
                showStatus: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: context.textStyles.username.copyWith(
                        color: _kPreviewUsernameColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    StarMarkdown(
                      data: message,
                      config: createStarMarkdownConfig(
                        context: context,
                        alwaysUnderlineLinks: appearance.alwaysUnderlineLinks,
                        dimStrikethroughText: appearance.dimStrikethroughText,
                        animateCustomEmoji: effectiveMotionOf(
                          ref,
                          context,
                        ).effectiveAnimateEmoji,
                      ),
                      baseStyle: context.textStyles.messageText.copyWith(
                        color: colors.textChat,
                      ),
                      astParser: parseNativeStarMarkdownAst,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
