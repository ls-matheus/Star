import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/accessibility/domain/resolve_reduced_motion.dart';
import 'package:star_app/features/accessibility/providers/effective_motion_preferences_provider.dart';
import 'package:star_app/features/settings/presentation/widgets/accessibility_saturation_slider.dart';
import 'package:star_app/features/settings/presentation/widgets/user_accessibility_animation_section.dart';
import 'package:star_app/features/settings/presentation/widgets/user_accessibility_keyboard_section.dart';
import 'package:star_app/features/settings/presentation/widgets/user_accessibility_preview.dart';
import 'package:star_app/features/settings/presentation/widgets/user_accessibility_tts_section.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';

class UserAccessibility extends ConsumerWidget {
  const UserAccessibility({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearancePreferencesProvider);
    final appearanceNotifier = ref.read(appearancePreferencesProvider.notifier);
    final l10n = StarLocalizations.of(context);
    final bool showPreview = !isMobileLayout(context);
    final bool showKeyboard = !isTouchPrimaryInput(ref);
    final bool platformReducedMotion = platformReducedMotionOf(ref, context);
    final bool reducedMotion = resolveReducedMotion(
      syncReducedMotionWithSystem: appearance.syncReducedMotionWithSystem,
      reducedMotionOverride: appearance.reducedMotionOverride,
      platformReducedMotion: platformReducedMotion,
    );
    final String reduceMotionBaseDescription =
        appearance.syncReducedMotionWithSystem
        ? l10n.accessibilityReducedMotionOverrideSyncedDescription
        : l10n.accessibilityReducedMotionOverrideManualDescription;
    final String reduceMotionDescription = reducedMotion
        ? '$reduceMotionBaseDescription ${l10n.accessibilityReducedMotionAnimationTabHint}'
        : reduceMotionBaseDescription;

    final layout = context.layout;

    return SingleChildScrollView(
      controller: scrollController,
      padding: settingsScrollPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showPreview) ...[
            const UserAccessibilityPreview(),
            SizedBox(height: layout.s8),
          ],
          StarSettingsSection(
            sectionId: 'visual',
            title: l10n.accessibilityVisualGroupTitle,
            isFirst: true,
            children: [
              StarSettingsSubsection(
                title: l10n.accessibilitySaturationTitle,
                children: const [AccessibilitySaturationSlider()],
              ),
              StarSettingsSwitchGroup(
                children: [
                  StarSettingsSwitchItem.grouped(
                    label: l10n.accessibilityAlwaysUnderlineLinksLabel,
                    value: appearance.alwaysUnderlineLinks,
                    onChanged: (value) => unawaited(
                      appearanceNotifier.setAlwaysUnderlineLinks(value: value),
                    ),
                  ),
                  StarSettingsSwitchItem.grouped(
                    label: l10n.accessibilityShowAltTextOnImagesLabel,
                    description:
                        l10n.accessibilityShowAltTextOnImagesDescription,
                    value: appearance.showAltTextOnImages,
                    onChanged: (value) => unawaited(
                      appearanceNotifier.setShowAltTextOnImages(value: value),
                    ),
                  ),
                  StarSettingsSwitchItem.grouped(
                    label: l10n.accessibilityDimStrikethroughTextLabel,
                    value: appearance.dimStrikethroughText,
                    onChanged: (value) => unawaited(
                      appearanceNotifier.setDimStrikethroughText(value: value),
                    ),
                  ),
                ],
              ),
              StarSettingsSubsection(
                title: l10n.accessibilityDmMessagePreviewGroupTitle,
                children: [
                  Semantics(
                    label: l10n.accessibilityDmMessagePreviewModeLabel,
                    container: true,
                    child: StarRadioGroup<DmMessagePreviewMode>(
                      value: appearance.dmMessagePreviewMode,
                      onChanged: (value) => unawaited(
                        appearanceNotifier.setDmMessagePreviewMode(value),
                      ),
                      items: [
                        StarRadioItem(
                          value: DmMessagePreviewMode.all,
                          label: l10n.accessibilityDmMessagePreviewAllName,
                          description:
                              l10n.accessibilityDmMessagePreviewAllDescription,
                        ),
                        StarRadioItem(
                          value: DmMessagePreviewMode.unreadOnly,
                          label:
                              l10n.accessibilityDmMessagePreviewUnreadOnlyName,
                          description: l10n
                              .accessibilityDmMessagePreviewUnreadOnlyDescription,
                        ),
                        StarRadioItem(
                          value: DmMessagePreviewMode.none,
                          label: l10n.accessibilityDmMessagePreviewNoneName,
                          description:
                              l10n.accessibilityDmMessagePreviewNoneDescription,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StarSettingsSection(
            sectionId: 'screen-reader',
            title: l10n.accessibilityScreenReaderGroupTitle,
            description: l10n.accessibilityScreenReaderGroupDescription(
              ref.watch(
                instanceRuntimeConfigProvider.select(
                  (config) => config.productName,
                ),
              ),
            ),
            children: [
              StarSettingsSwitchGroup(
                children: [
                  StarSettingsSwitchItem.grouped(
                    label:
                        l10n.accessibilityScreenReaderAnnounceNewMessagesLabel,
                    description: l10n
                        .accessibilityScreenReaderAnnounceNewMessagesDescription,
                    value: appearance.screenReaderAnnounceNewMessages,
                    onChanged: (value) => unawaited(
                      appearanceNotifier.setScreenReaderAnnounceNewMessages(
                        value: value,
                      ),
                    ),
                  ),
                  StarSettingsSwitchItem.grouped(
                    label: l10n.accessibilityAnnounceCallJoinsAndLeavesLabel,
                    description:
                        l10n.accessibilityAnnounceCallJoinsAndLeavesDescription,
                    value: appearance.announceCallJoinsAndLeaves,
                    onChanged: (value) => unawaited(
                      appearanceNotifier.setAnnounceCallJoinsAndLeaves(
                        value: value,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const UserAccessibilityTtsSection(),
          if (showKeyboard) const UserAccessibilityKeyboardSection(),
          const UserAccessibilityAnimationSection(),
          StarSettingsSection(
            sectionId: 'motion',
            title: l10n.accessibilityMotionGroupTitle,
            children: [
              StarSettingsSwitchGroup(
                children: [
                  StarSettingsSwitchItem.grouped(
                    label: l10n.accessibilitySyncReducedMotionWithSystemLabel,
                    description: l10n
                        .accessibilitySyncReducedMotionWithSystemDescription,
                    value: appearance.syncReducedMotionWithSystem,
                    onChanged: (value) => unawaited(
                      appearanceNotifier.setSyncReducedMotionWithSystem(
                        value: value,
                      ),
                    ),
                  ),
                  StarSettingsSwitchItem.grouped(
                    label: l10n.accessibilityReducedMotionOverrideLabel,
                    description: reduceMotionDescription,
                    value: appearance.syncReducedMotionWithSystem
                        ? reducedMotion
                        : appearance.reducedMotionOverride,
                    enabled: !appearance.syncReducedMotionWithSystem,
                    onChanged: (value) => unawaited(
                      appearanceNotifier.setReducedMotionOverride(value: value),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
