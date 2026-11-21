import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/platform/star_platform.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/chat/presentation/sheets/double_tap_reaction_picker_sheet.dart';
import 'package:star_app/features/chat/presentation/widgets/message_actions/double_tap_reaction_hint.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/settings/providers/preferences/chat_preferences_provider.dart';
import 'package:star_app/features/settings/providers/preferences/message_ui_preferences_providers.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/settings/utils/user_settings/user_settings_domain_actions.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/external_links/external_link_utils.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';
import 'package:star_dart/export.dart';

class UserMessagesMedia extends ConsumerWidget {
  const UserMessagesMedia({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userSettingsViewModelProvider);
    final notifier = ref.read(userSettingsViewModelProvider.notifier);
    final chat = ref.watch(chatPreferencesProvider);
    final chatNotifier = ref.read(chatPreferencesProvider.notifier);
    final chatInputPrefs = ref.watch(chatInputPreferencesProvider);
    final chatInputPrefsNotifier = ref.read(
      chatInputPreferencesProvider.notifier,
    );
    final doubleTapActionPrefs = ref.watch(doubleTapActionPreferencesProvider);
    final doubleTapActionPrefsNotifier = ref.read(
      doubleTapActionPreferencesProvider.notifier,
    );
    final l10n = StarLocalizations.of(context);
    final bool showGestures =
        isStarNativeMobileOs && ref.watch(inputModalityProvider);
    final doubleTapAction =
        doubleTapActionPrefs.action == DoubleTapActionPreference.unspecified
        ? DoubleTapActionPreference.react
        : doubleTapActionPrefs.action;
    final swipeRightToLeftPrefs = ref.watch(
      swipeRightToLeftActionPreferencesProvider,
    );
    final swipeRightToLeftPrefsNotifier = ref.read(
      swipeRightToLeftActionPreferencesProvider.notifier,
    );
    final swipeRightToLeftAction =
        swipeRightToLeftPrefs.action ==
            SwipeRightToLeftActionPreference.unspecified
        ? SwipeRightToLeftActionPreference.reply
        : swipeRightToLeftPrefs.action;

    final mediaSizeItems = [
      StarRadioItem(
        value: MediaDimensionSize.small,
        label: l10n.messagesMediaSizeCompactName,
        description: l10n.messagesMediaSizeCompactDescription,
      ),
      StarRadioItem(
        value: MediaDimensionSize.large,
        label: l10n.messagesMediaSizeComfortableName,
        description: l10n.messagesMediaSizeComfortableDescription,
      ),
    ];

    return SingleChildScrollView(
      controller: scrollController,
      padding: settingsScrollPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StarSettingsSection(
            sectionId: 'display',
            title: l10n.messagesMediaDisplayGroupTitle,
            description: l10n.messagesMediaDisplayGroupDescription,
            isFirst: true,
            children: [
              StarSettingsSubsection(
                title: l10n.messagesMediaDisplaySectionTitle,
                description: l10n.messagesMediaDisplaySectionDescription,
                children: [
                  StarSettingsSwitchGroup(
                    children: [
                      StarSettingsSwitchItem.grouped(
                        label: l10n.messagesMediaDisplayInlineEmbedLabel,
                        value: state.inlineEmbedMedia,
                        onChanged: (value) =>
                            notifier.setInlineEmbedMedia(value: value),
                      ),
                      StarSettingsSwitchItem.grouped(
                        label: l10n.messagesMediaDisplayInlineAttachmentLabel(
                          ref.watch(
                            instanceRuntimeConfigProvider.select(
                              (config) => config.productName,
                            ),
                          ),
                        ),
                        value: state.inlineAttachmentMedia,
                        onChanged: (value) =>
                            notifier.setInlineAttachmentMedia(value: value),
                      ),
                    ],
                  ),
                ],
              ),
              StarSettingsSubsection(
                title: l10n.messagesMediaLinkPreviewsSectionTitle,
                description: l10n.messagesMediaLinkPreviewsSectionDescription,
                children: [
                  StarSettingsSwitchItem(
                    label: l10n.messagesMediaLinkPreviewsToggleLabel,
                    value: state.renderEmbeds,
                    onChanged: (value) =>
                        notifier.setRenderEmbeds(value: value),
                  ),
                ],
              ),
              StarSettingsSubsection(
                title: l10n.messagesMediaReactionsSectionTitle,
                description: l10n.messagesMediaReactionsSectionDescription,
                children: [
                  StarSettingsSwitchItem(
                    label: l10n.messagesMediaReactionsToggleLabel,
                    value: state.renderReactions,
                    onChanged: (value) =>
                        notifier.setRenderReactions(value: value),
                  ),
                ],
              ),
              StarSettingsSubsection(
                title: l10n.messagesMediaSpoilersSectionTitle,
                description: l10n.messagesMediaSpoilersSectionDescription,
                children: [
                  StarRadioGroup<RenderSpoilers>(
                    label: l10n.messagesMediaSpoilersRadioLabel,
                    value: state.renderSpoilers,
                    onChanged: notifier.setRenderSpoilers,
                    items: [
                      StarRadioItem(
                        value: RenderSpoilers.onClick,
                        label: l10n.messagesMediaSpoilersOnClickName,
                        description:
                            l10n.messagesMediaSpoilersOnClickDescription,
                      ),
                      StarRadioItem(
                        value: RenderSpoilers.ifModerator,
                        label: l10n.messagesMediaSpoilersIfModeratorName,
                        description:
                            l10n.messagesMediaSpoilersIfModeratorDescription,
                      ),
                      StarRadioItem(
                        value: RenderSpoilers.always,
                        label: l10n.messagesMediaSpoilersAlwaysName,
                        description:
                            l10n.messagesMediaSpoilersAlwaysDescription,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StarSettingsSection(
            sectionId: 'media',
            title: l10n.messagesMediaMediaGroupTitle,
            description: l10n.messagesMediaMediaGroupDescription,
            children: [
              StarSettingsSubsection(
                title: l10n.messagesMediaSizeSectionTitle,
                description: l10n.messagesMediaSizeSectionDescription,
                children: [
                  StarRadioGroup<MediaDimensionSize>(
                    label: l10n.messagesMediaSizeEmbedLabel,
                    value: chat.embedMediaDimensionSize,
                    onChanged: chatNotifier.setEmbedMediaDimensionSize,
                    items: mediaSizeItems,
                  ),
                  StarRadioGroup<MediaDimensionSize>(
                    label: l10n.messagesMediaSizeAttachmentLabel,
                    value: chat.attachmentMediaDimensionSize,
                    onChanged: chatNotifier.setAttachmentMediaDimensionSize,
                    items: mediaSizeItems,
                  ),
                ],
              ),
              StarSettingsSubsection(
                title: l10n.messagesMediaGifsSectionTitle,
                description: l10n.messagesMediaGifsSectionDescription,
                children: [
                  StarSettingsSwitchItem(
                    label: l10n.messagesMediaGifsAutoSendLabel,
                    value: chat.autoSendKlipyGifs,
                    onChanged: (value) =>
                        chatNotifier.setAutoSendKlipyGifs(value: value),
                  ),
                ],
              ),
              if (isStarNativeMobileOs)
                StarSettingsSubsection(
                  title: l10n.messagesMediaCameraUploadsSectionTitle,
                  description:
                      l10n.messagesMediaCameraUploadsSectionDescription,
                  children: [
                    StarSettingsSwitchItem(
                      label: l10n.messagesMediaCameraUploadsSaveToDeviceLabel,
                      value: chatInputPrefs.saveCameraCapturesToDevice,
                      onChanged: (value) => chatInputPrefsNotifier
                          .setSaveCameraCapturesToDevice(value: value),
                    ),
                  ],
                ),
            ],
          ),
          if (showGestures)
            StarSettingsSection(
              sectionId: 'gestures',
              title: l10n.messagesMediaGesturesSectionTitle,
              description: l10n.messagesMediaGesturesSectionDescription,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StarRadioGroup<DoubleTapActionPreference>(
                      label: l10n.messagesMediaGesturesDoubleTapActionLabel,
                      value: doubleTapAction,
                      onChanged: doubleTapActionPrefsNotifier.setAction,
                      items: [
                        StarRadioItem(
                          value: DoubleTapActionPreference.react,
                          label: l10n
                              .messagesMediaGesturesDoubleTapActionReactName,
                          description: l10n
                              .messagesMediaGesturesDoubleTapActionReactDescription,
                        ),
                        StarRadioItem(
                          value: DoubleTapActionPreference.edit,
                          label:
                              l10n.messagesMediaGesturesDoubleTapActionEditName,
                          description: l10n
                              .messagesMediaGesturesDoubleTapActionEditDescription,
                        ),
                        StarRadioItem(
                          value: DoubleTapActionPreference.none,
                          label:
                              l10n.messagesMediaGesturesDoubleTapActionNoneName,
                          description: l10n
                              .messagesMediaGesturesDoubleTapActionNoneDescription,
                        ),
                      ],
                    ),
                    if (doubleTapAction == DoubleTapActionPreference.react) ...[
                      SizedBox(height: context.layout.s4),
                      StarSettingsAccessoryRow(
                        label: l10n.messagesMediaGesturesReactionLabel,
                        description:
                            l10n.messagesMediaGesturesReactionDescription,
                        onTap: () => unawaited(
                          showDoubleTapReactionPicker(context, ref),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const DoubleTapReactionGlyph(size: 24),
                            SizedBox(width: context.layout.s2),
                            PhosphorIcon(
                              PhosphorIconsBold.caretRight,
                              size: 18,
                              color: context.colors.textPrimaryMuted,
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: context.layout.s4),
                    StarRadioGroup<SwipeRightToLeftActionPreference>(
                      label: l10n.messagesMediaGesturesSwipeRightToLeftLabel,
                      value: swipeRightToLeftAction,
                      onChanged: swipeRightToLeftPrefsNotifier.setAction,
                      items: [
                        StarRadioItem(
                          value: SwipeRightToLeftActionPreference.reply,
                          label: l10n
                              .messagesMediaGesturesSwipeRightToLeftReplyName,
                          description: l10n
                              .messagesMediaGesturesSwipeRightToLeftReplyDescription,
                        ),
                        StarRadioItem(
                          value:
                              SwipeRightToLeftActionPreference.channelDetails,
                          label: l10n
                              .messagesMediaGesturesSwipeRightToLeftChannelDetailsName,
                          description: l10n
                              .messagesMediaGesturesSwipeRightToLeftChannelDetailsDescription,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          StarSettingsSection(
            sectionId: 'input',
            title: l10n.messagesMediaInputGroupTitle,
            description: l10n.messagesMediaInputGroupDescription,
            children: [
              StarSettingsSubsection(
                title: l10n.messagesMediaAutocompleteSectionTitle,
                description: l10n.messagesMediaAutocompleteSectionDescription,
                children: [
                  StarSettingsSwitchGroup(
                    children: [
                      StarSettingsSwitchItem.grouped(
                        label: l10n.messagesMediaAutocompleteDefaultEmojisLabel,
                        value: chat.showDefaultEmojisInExpressionAutocomplete,
                        onChanged: (value) => chatNotifier
                            .setShowDefaultEmojisInExpressionAutocomplete(
                              value: value,
                            ),
                      ),
                      StarSettingsSwitchItem.grouped(
                        label: l10n.messagesMediaAutocompleteCustomEmojisLabel,
                        value: chat.showCustomEmojisInExpressionAutocomplete,
                        onChanged: (value) => chatNotifier
                            .setShowCustomEmojisInExpressionAutocomplete(
                              value: value,
                            ),
                      ),
                      StarSettingsSwitchItem.grouped(
                        label: l10n.messagesMediaAutocompleteStickersLabel,
                        value: chat.showStickersInExpressionAutocomplete,
                        onChanged: (value) => chatNotifier
                            .setShowStickersInExpressionAutocomplete(
                              value: value,
                            ),
                      ),
                      StarSettingsSwitchItem.grouped(
                        label: l10n.messagesMediaAutocompleteSavedMediaLabel,
                        value: chat.showMemesInExpressionAutocomplete,
                        onChanged: (value) => chatNotifier
                            .setShowMemesInExpressionAutocomplete(value: value),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StarSettingsSection(
            title: l10n.externalLinksSectionTitle,
            description: l10n.externalLinksSectionDescription,
            children: [
              StarSettingsSwitchItem(
                label: l10n.externalLinkTrustAllLabel,
                description: trustedDomainsDescription(
                  l10n: l10n,
                  trustAll: state.trustAllDomains,
                  trustedCount: state.trustedDomainsCount,
                ),
                value: state.trustAllDomains,
                onChanged: (value) =>
                    handleTrustAllDomainsChange(context, ref, value: value),
              ),
              StarSettingsSwitchItem(
                label: l10n.externalLinkStripTrackingLabel,
                description: l10n.externalLinkStripTrackingDescription,
                value: chat.sanitizeUrls,
                onChanged: (value) =>
                    chatNotifier.setSanitizeUrls(value: value),
              ),
            ],
          ),
          StarSettingsSection(
            title: l10n.messagesMediaSidebarGroupTitle,
            description: l10n.messagesMediaSidebarGroupDescription,
            children: [
              StarSettingsSwitchItem(
                label: l10n.messagesMediaDefaultHideMutedChannelsLabel,
                description:
                    l10n.messagesMediaDefaultHideMutedChannelsDescription,
                value: state.defaultHideMutedChannels,
                onChanged: (value) => handleDefaultHideMutedChannelsChange(
                  context,
                  ref,
                  value: value,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
