import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/limits/instance_limit_provider.dart';
import 'package:star_app/core/limits/limit_key.dart';
import 'package:star_app/core/premium/should_show_premium_commerce_provider.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/chat/presentation/widgets/composer/composer_autocomplete_field.dart';
import 'package:star_app/features/chat/presentation/widgets/pickers/expression_picker.dart';
import 'package:star_app/features/chat/services/composer_autocomplete_trigger.dart';
import 'package:star_app/features/guilds/providers/guild_list_view_model.dart';
import 'package:star_app/features/settings/domain/guild_asset_mode.dart';
import 'package:star_app/features/settings/presentation/widgets/star_tag_change_sheet.dart';
import 'package:star_app/features/settings/presentation/widgets/image_crop_sheet.dart';
import 'package:star_app/features/settings/presentation/widgets/profile_badge_settings_section.dart';
import 'package:star_app/features/settings/presentation/widgets/profile_local_time_settings_section.dart';
import 'package:star_app/features/settings/presentation/widgets/profile_preview_card.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/settings/utils/commerce/open_user_billing_settings.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/ui/icons/plutonium_product_icon.dart';
import 'package:star_app/features/ui/input/emoji_text_editing_controller.dart';
import 'package:star_app/features/ui/input/inline_token_text_editing_controller.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/utils/api_error_presentation.dart';
import 'package:star_app/shared/utils/image_utils.dart';

const int _kMaxDisplayNameLength = 32;
const int _kMaxPronounsLength = 40;
const int _kDefaultProfileAccentColor = 0x4641D9;

int _accentColorPickerValue(UserSettingsViewState state) {
  if (state.isPerGuildProfile) {
    if (state.isEditedGuildAccentColorSet) {
      return state.editedGuildAccentColor ?? _kDefaultProfileAccentColor;
    }
    return state.guildAccentColor ??
        state.accentColor ??
        _kDefaultProfileAccentColor;
  }
  if (state.isEditedAccentColorSet) {
    return state.editedAccentColor ?? _kDefaultProfileAccentColor;
  }
  return state.accentColor ?? _kDefaultProfileAccentColor;
}

bool _accentColorIsDefault(UserSettingsViewState state) {
  if (state.isPerGuildProfile) {
    if (state.isEditedGuildAccentColorSet) {
      return state.editedGuildAccentColor == null;
    }
    return state.guildAccentColor == null && state.accentColor == null;
  }
  if (state.isEditedAccentColorSet) {
    return state.editedAccentColor == null;
  }
  return state.accentColor == null;
}

class UserProfile extends ConsumerStatefulWidget {
  const UserProfile({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  ConsumerState<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends ConsumerState<UserProfile> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _pronounsController;
  late final EmojiTextEditingController _bioController;
  late final TextEditingController _nickController;
  late final TextEditingController _guildPronounsController;
  late final EmojiTextEditingController _guildBioController;
  final _expressionPickerKey = GlobalKey<StarEmojiPickerPopoutState>();

  bool _controllersInitialized = false;
  final FocusNode _bioFocusNode = FocusNode();
  final GlobalKey<ComposerAutocompleteFieldState> _bioFieldKey =
      GlobalKey<ComposerAutocompleteFieldState>();

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _pronounsController = TextEditingController();
    _bioController = EmojiTextEditingController();
    _nickController = TextEditingController();
    _guildPronounsController = TextEditingController();
    _guildBioController = EmojiTextEditingController();
    _bioFocusNode.onKeyEvent = (FocusNode node, KeyEvent event) {
      return handleComposerAutocompleteKey(_bioFieldKey.currentState, event);
    };
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _pronounsController.dispose();
    _bioController.dispose();
    _nickController.dispose();
    _guildPronounsController.dispose();
    _guildBioController.dispose();
    _bioFocusNode.dispose();
    super.dispose();
  }

  void _syncControllers(UserSettingsViewState state) {
    if (!_controllersInitialized && state.isProfileLoaded) {
      _resetControllers(state);
      _controllersInitialized = true;
    }
  }

  void _resetControllers(UserSettingsViewState state) {
    _displayNameController.text = state.isEditedDisplayNameSet
        ? (state.editedDisplayName ?? '')
        : state.displayName;
    _pronounsController.text = state.isEditedPronounsSet
        ? (state.editedPronouns ?? '')
        : (state.pronouns ?? '');
    _bioController.loadWithTokens(
      state.isEditedBioSet ? (state.editedBio ?? '') : (state.bio ?? ''),
    );
    _nickController.text = state.isEditedNickSet
        ? (state.editedNick ?? '')
        : (state.guildNick ?? '');
    _guildPronounsController.text = state.isEditedGuildPronounsSet
        ? (state.editedGuildPronouns ?? '')
        : (state.guildPronouns ?? '');
    _guildBioController.loadWithTokens(
      state.isEditedGuildBioSet
          ? (state.editedGuildBio ?? '')
          : (state.guildBio ?? ''),
    );
  }

  void _notifyBioChanged() {
    final vm = ref.read(userSettingsViewModelProvider.notifier);
    final state = ref.read(userSettingsViewModelProvider);
    if (state.isPerGuildProfile) {
      vm.updateGuildBio(_guildBioController.actualText);
    } else {
      vm.updateBio(_bioController.actualText);
    }
  }

  void _onSmileyTap() {
    if (isMobileLayout(context)) {
      final state = ref.read(userSettingsViewModelProvider);
      final controller = state.isPerGuildProfile
          ? _guildBioController
          : _bioController;
      unawaited(
        StarEmojiPickerSheet.show(
          context,
          title: StarLocalizations.of(context).emojiPickerTitle,
          onEmojiSelected: (emoji) {
            controller.insertEmoji(
              emoji.name,
              emoji.surrogates,
              maxActualLength: ref.read(
                instanceLimitProvider(LimitKeys.maxBioLength),
              ),
            );
            _notifyBioChanged();
          },
          visibleTabs: const [ExpressionPickerTab.emojis],
        ),
      );
    } else {
      _expressionPickerKey.currentState?.toggle();
    }
  }

  Widget _buildUnclaimedAccountBar(
    StarLayoutTheme layout,
    StarLocalizations l10n,
  ) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.backgroundSecondaryAlt,
        border: Border(top: BorderSide(color: colors.accentWarning, width: 2)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: layout.s4,
          right: layout.s4,
          top: layout.s3,
          bottom: bottomPadding > 0 ? bottomPadding : layout.s3,
        ),
        child: Row(
          children: [
            PhosphorIcon(
              PhosphorIconsBold.warning,
              color: colors.accentWarning,
              size: 20,
            ),
            SizedBox(width: layout.s2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.unclaimedAccountTitle,
                    style: textStyles.bodySmall.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: layout.s1),
                  Text(
                    ref.watch(
                          userSettingsViewModelProvider.select(
                            (s) => s.usernameSignIn,
                          ),
                        )
                        ? l10n.unclaimedAccountDescriptionUsername
                        : l10n.unclaimedAccountDescription,
                    style: textStyles.smallText.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImageUpload({required bool isAvatar}) async {
    final picked = await ImageUtils.pickImage();
    if (picked == null || !mounted) {
      return;
    }

    if (ImageUtils.isOverSizeLimit(picked.bytes)) {
      if (!mounted) {
        return;
      }
      final l10n = StarLocalizations.of(context);
      await showErrorDialog(
        context,
        title: isAvatar
            ? l10n.avatarUploadFailedTitle
            : l10n.bannerUploadFailedTitle,
        body: l10n.imageFileTooLarge,
      );
      return;
    }

    final animCheck = ImageUtils.checkAnimated(picked.bytes);

    if (animCheck.isAnimated) {
      final bool hasAnimatedEntitlement = isAvatar
          ? ref.read(
              instanceFeatureEnabledProvider(LimitKeys.featureAnimatedAvatar),
            )
          : ref.read(
              instanceFeatureEnabledProvider(LimitKeys.featureAnimatedBanner),
            );
      if (!hasAnimatedEntitlement) {
        if (!mounted) {
          return;
        }
        final l10n = StarLocalizations.of(context);
        await showErrorDialog(
          context,
          title: isAvatar
              ? l10n.animatedAvatarsRequirePlutonium
              : l10n.animatedBannersRequirePlutonium,
          body: l10n.animatedImageUseStatic,
        );
        return;
      }

      if (animCheck.format == 'avif') {
        if (!mounted) {
          return;
        }
        final l10n = StarLocalizations.of(context);
        final confirmed = await StarBottomSheet.show<bool>(
          context,
          title: l10n.animatedAvifNotSupported,
          builder: (sheetContext, _) => Padding(
            padding: EdgeInsets.fromLTRB(
              sheetContext.layout.s4,
              sheetContext.layout.s4,
              sheetContext.layout.s4,
              0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.animatedAvifNotSupportedBody,
                  style: sheetContext.textStyles.bodyMedium.copyWith(
                    color: sheetContext.colors.textSecondary,
                  ),
                ),
                SizedBox(height: sheetContext.layout.s4),
                StarButton.primary(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  label: l10n.uploadAsIs,
                ),
                SizedBox(height: sheetContext.layout.s2),
                StarButton.secondary(
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                  label: l10n.cancel,
                ),
              ],
            ),
          ),
        );
        if (confirmed != true || !mounted) {
          return;
        }
      } else {
        ref
            .read(toastProvider.notifier)
            .show(
              StarToast(
                message: StarLocalizations.of(
                  context,
                ).croppingAnimatedNotSupported,
              ),
            );
      }

      final dataUri = ImageUtils.toDataUri(picked.bytes);
      final vm = ref.read(userSettingsViewModelProvider.notifier);
      if (ref.read(userSettingsViewModelProvider).isPerGuildProfile) {
        if (isAvatar) {
          vm.setGuildAvatar(dataUri);
        } else {
          vm.setGuildBanner(dataUri);
        }
      } else {
        if (isAvatar) {
          vm.setAvatar(dataUri);
        } else {
          vm.setBanner(dataUri);
        }
      }
      return;
    }

    if (!mounted) {
      return;
    }
    final croppedBytes = await showImageCropSheet(
      context,
      imageBytes: picked.bytes,
      aspectRatio: isAvatar ? 1.0 : 17.0 / 6.0,
      title: isAvatar
          ? StarLocalizations.of(context).cropAvatar
          : StarLocalizations.of(context).cropBanner,
      maskShape: isAvatar ? CropMaskShape.circle : CropMaskShape.rectangle,
    );

    if (croppedBytes == null || !mounted) {
      return;
    }

    final dataUri = ImageUtils.toDataUri(croppedBytes);
    final vm = ref.read(userSettingsViewModelProvider.notifier);
    if (ref.read(userSettingsViewModelProvider).isPerGuildProfile) {
      if (isAvatar) {
        vm.setGuildAvatar(dataUri);
      } else {
        vm.setGuildBanner(dataUri);
      }
    } else {
      if (isAvatar) {
        vm.setAvatar(dataUri);
      } else {
        vm.setBanner(dataUri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userSettingsViewModelProvider);
    final bool hasPerGuildProfiles = ref.watch(
      instanceFeatureEnabledProvider(LimitKeys.featurePerGuildProfiles),
    );
    final bool shouldShowPremiumCommerce = ref.watch(
      shouldShowPremiumCommerceProvider,
    );
    _syncControllers(state);

    ref
      ..listen(userSettingsViewModelProvider.select((s) => s.isDirty), (
        prev,
        next,
      ) {
        if ((prev ?? false) && !next) {
          _resetControllers(ref.read(userSettingsViewModelProvider));
        }
      })
      ..listen(
        userSettingsViewModelProvider.select((s) => s.isLoadingGuildProfile),
        (prev, next) {
          if ((prev ?? false) && !next) {
            final currentState = ref.read(userSettingsViewModelProvider);
            _nickController.text = currentState.guildNick ?? '';
            _guildPronounsController.text = currentState.guildPronouns ?? '';
            _guildBioController.loadWithTokens(currentState.guildBio ?? '');
          }
        },
      )
      ..listen(
        userSettingsViewModelProvider.select(
          (s) => (s.bio, s.pronouns, s.displayName),
        ),
        (prev, next) {
          final s = ref.read(userSettingsViewModelProvider);
          if (!s.isDirty && !s.isPerGuildProfile) {
            _displayNameController.text = s.displayName;
            _pronounsController.text = s.pronouns ?? '';
            _bioController.loadWithTokens(s.bio ?? '');
          }
        },
      )
      ..listen(userSettingsViewModelProvider.select((s) => s.isSaving), (
        prev,
        next,
      ) {
        if ((prev ?? false) && !next) {
          final s = ref.read(userSettingsViewModelProvider);
          if (s.error == null) {
            ref
                .read(toastProvider.notifier)
                .show(
                  StarToast(
                    message: StarLocalizations.of(context).profileSavedToast,
                    variant: StarToastVariant.success,
                  ),
                );
          }
        }
      });

    if (!state.isProfileLoaded) {
      return const Center(child: StarLoadingSpinner());
    }

    final vm = ref.read(userSettingsViewModelProvider.notifier);
    final layout = context.layout;
    final l10n = StarLocalizations.of(context);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: widget.scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: settingsScrollPaddingWithSaveBar(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StarSettingsSection(
                  title: l10n.profileCustomizationTitle,
                  description: l10n.profileCustomizationDescription,
                  isFirst: true,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileTypeSelector(state, vm, layout, l10n),
                        if (state.isLoadingGuildProfile) ...[
                          SizedBox(height: layout.s6),
                          const Center(child: StarLoadingSpinner()),
                        ],
                        if (!state.isPerGuildProfile) ...[
                          SizedBox(height: layout.s6),
                          _buildUsernameSection(state, layout, l10n),
                        ],
                        if (!state.isPerGuildProfile) ...[
                          SizedBox(height: layout.s6),
                          StarInput(
                            controller: _displayNameController,
                            label: l10n.displayNameLabel,
                            hint: state.username,
                            maxLength: _kMaxDisplayNameLength,
                            textCapitalization: TextCapitalization.words,
                            onChanged: vm.updateDisplayName,
                            onTapOutside: (_) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                          ),
                        ],
                        if (state.isPerGuildProfile &&
                            !state.isLoadingGuildProfile) ...[
                          SizedBox(height: layout.s6),
                          StarInput(
                            controller: _nickController,
                            label: l10n.communityNicknameLabel,
                            hint: state.username,
                            maxLength: _kMaxDisplayNameLength,
                            enabled: state.canChangeNickname,
                            textCapitalization: TextCapitalization.words,
                            onChanged: vm.updateNick,
                            onTapOutside: (_) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                          ),
                        ],
                        SizedBox(height: layout.s6),
                        StarInput(
                          controller: state.isPerGuildProfile
                              ? _guildPronounsController
                              : _pronounsController,
                          label: l10n.pronounsLabel,
                          maxLength: _kMaxPronounsLength,
                          onChanged: state.isPerGuildProfile
                              ? vm.updateGuildPronouns
                              : vm.updatePronouns,
                          onTapOutside: (_) =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                        ),
                        if (!state.isPerGuildProfile) ...[
                          SizedBox(height: layout.s6),
                          ProfileLocalTimeSettingsSection(
                            disabled: state.needsKnownEmailVerification,
                          ),
                        ],
                        if (state.isPerGuildProfile &&
                            !hasPerGuildProfiles &&
                            shouldShowPremiumCommerce &&
                            !state.isLoadingGuildProfile) ...[
                          SizedBox(height: layout.s6),
                          _buildPerGuildPremiumUpsell(l10n),
                        ],
                        if (!state.isPerGuildProfile) ...[
                          SizedBox(height: layout.s6),
                          _buildAvatarSection(state, vm, layout, l10n),
                          SizedBox(height: layout.s6),
                          _buildBannerSection(state, vm, layout, l10n),
                        ] else if (!state.isLoadingGuildProfile) ...[
                          SizedBox(height: layout.s6),
                          Opacity(
                            opacity: hasPerGuildProfiles ? 1.0 : 0.5,
                            child: IgnorePointer(
                              ignoring: !hasPerGuildProfiles,
                              child: _buildGuildAvatarSection(
                                state,
                                vm,
                                layout,
                                l10n,
                              ),
                            ),
                          ),
                          SizedBox(height: layout.s6),
                          Opacity(
                            opacity: hasPerGuildProfiles ? 1.0 : 0.5,
                            child: IgnorePointer(
                              ignoring: !hasPerGuildProfiles,
                              child: _buildGuildBannerSection(
                                state,
                                vm,
                                layout,
                                l10n,
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: layout.s6),
                        Opacity(
                          opacity:
                              state.isPerGuildProfile && !hasPerGuildProfiles
                              ? 0.5
                              : 1.0,
                          child: IgnorePointer(
                            ignoring:
                                state.isPerGuildProfile && !hasPerGuildProfiles,
                            child: StarColorPickerField(
                              label: l10n.accentColorLabel,
                              description: l10n.accentColorDescription,
                              value: _accentColorPickerValue(state),
                              defaultValue: _kDefaultProfileAccentColor,
                              isDefaultValue: _accentColorIsDefault(state),
                              onReset: state.isPerGuildProfile
                                  ? vm.resetGuildAccentColor
                                  : vm.resetAccentColor,
                              onChanged: state.isPerGuildProfile
                                  ? vm.updateGuildAccentColor
                                  : vm.updateAccentColor,
                            ),
                          ),
                        ),
                        SizedBox(height: layout.s6),
                        Opacity(
                          opacity:
                              state.isPerGuildProfile && !hasPerGuildProfiles
                              ? 0.5
                              : 1.0,
                          child: IgnorePointer(
                            ignoring:
                                state.isPerGuildProfile && !hasPerGuildProfiles,
                            child: _buildBioSection(state, vm, layout, l10n),
                          ),
                        ),
                        SizedBox(height: layout.s8),
                        StarGestureDetector(
                          onTap: () =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                          behavior: HitTestBehavior.opaque,
                          child: ProfilePreviewCard(state: state),
                        ),
                        if (!state.isPerGuildProfile) ...[
                          SizedBox(height: layout.s8),
                          StarGestureDetector(
                            onTap: () =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                            behavior: HitTestBehavior.opaque,
                            child: ProfileBadgeSettingsSection(state: state),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!state.isClaimed) _buildUnclaimedAccountBar(layout, l10n),
      ],
    );
  }

  Widget _buildProfileTypeSelector(
    UserSettingsViewState state,
    UserSettingsViewModel vm,
    StarLayoutTheme layout,
    StarLocalizations l10n,
  ) {
    final guilds = ref.watch(
      guildListViewModelProvider.select((s) => s.guilds),
    );

    final items = <StarSelectItem<String>>[
      StarSelectItem(value: '', label: l10n.profileTypeGlobal),
      for (final guild in guilds)
        StarSelectItem(
          value: guild.id,
          label: guild.name,
          leading: StarGuildIconAvatar(
            name: guild.name,
            imageUrl: guild.iconUrl,
            size: 20,
          ),
        ),
    ];

    return StarSelect<String>(
      label: l10n.profileTypeLabel,
      items: items,
      value: state.selectedGuildId ?? '',
      enabled: !state.isDirty,
      description: state.isPerGuildProfile
          ? l10n.profileTypeGuildDescription
          : null,
      onChanged: (guildId) {
        unawaited(vm.selectGuild(guildId.isEmpty ? null : guildId));
      },
    );
  }

  Widget _buildPerGuildPremiumUpsell(StarLocalizations l10n) {
    return StarPlutoniumUpsell(
      text: l10n.perGuildPremiumUpsellText,
      buttonSize: StarButtonSize.small,
      onButtonPressed: () => unawaited(openPlutoniumCommerce(context, ref)),
    );
  }

  Widget _buildAssetModeSelector({
    required GuildAssetMode value,
    required ValueChanged<GuildAssetMode> onChanged,
    required StarLocalizations l10n,
  }) {
    return StarRadioGroup<GuildAssetMode>(
      value: value,
      onChanged: onChanged,
      items: [
        StarRadioItem(
          value: GuildAssetMode.inherit,
          label: l10n.avatarModeInherit,
        ),
        StarRadioItem(
          value: GuildAssetMode.custom,
          label: l10n.avatarModeCustom,
        ),
        StarRadioItem(
          value: GuildAssetMode.unset,
          label: l10n.avatarModeUnset,
        ),
      ],
    );
  }

  Widget _buildGuildAvatarSection(
    UserSettingsViewState state,
    UserSettingsViewModel vm,
    StarLayoutTheme layout,
    StarLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.avatarLabel,
          style: context.textStyles.label.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        SizedBox(height: layout.s2),
        _buildAssetModeSelector(
          value: state.guildAvatarMode,
          onChanged: vm.setGuildAvatarMode,
          l10n: l10n,
        ),
        if (state.guildAvatarMode == GuildAssetMode.custom) ...[
          SizedBox(height: layout.s3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StarButton.primary(
                onPressed: () => _handleImageUpload(isAvatar: true),
                label: l10n.changeAvatar,
              ),
              if (state.guildAvatar != null ||
                  state.editedGuildAvatarBase64 != null) ...[
                SizedBox(height: layout.s2),
                StarButton.secondary(
                  onPressed: vm.clearGuildAvatar,
                  label: l10n.removeAvatar,
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildGuildBannerSection(
    UserSettingsViewState state,
    UserSettingsViewModel vm,
    StarLayoutTheme layout,
    StarLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.bannerLabel,
          style: context.textStyles.label.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        SizedBox(height: layout.s2),
        _buildAssetModeSelector(
          value: state.guildBannerMode,
          onChanged: vm.setGuildBannerMode,
          l10n: l10n,
        ),
        if (state.guildBannerMode == GuildAssetMode.custom) ...[
          SizedBox(height: layout.s3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StarButton.primary(
                onPressed: () => _handleImageUpload(isAvatar: false),
                label: l10n.changeBanner,
              ),
              if (state.guildBanner != null ||
                  state.editedGuildBannerBase64 != null) ...[
                SizedBox(height: layout.s2),
                StarButton.secondary(
                  onPressed: vm.clearGuildBanner,
                  label: l10n.removeBanner,
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBioSection(
    UserSettingsViewState state,
    UserSettingsViewModel vm,
    StarLayoutTheme layout,
    StarLocalizations l10n,
  ) {
    final colors = context.colors;
    final controller = state.isPerGuildProfile
        ? _guildBioController
        : _bioController;
    final int maxBioLength = ref.watch(
      instanceLimitProvider(LimitKeys.maxBioLength),
    );
    final onChanged = state.isPerGuildProfile
        ? () => vm.updateGuildBio(controller.actualText)
        : () => vm.updateBio(controller.actualText);

    return TextFieldTapRegion(
      child: ComposerAutocompleteField(
        key: _bioFieldKey,
        controller: controller,
        focusNode: _bioFocusNode,
        allowedTriggers: const <ComposerAutocompleteTriggerKind>{
          ComposerAutocompleteTriggerKind.emoji,
        },
        maxActualLength: maxBioLength,
        onApplied: onChanged,
        child: StarInput.multiline(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          focusNode: _bioFocusNode,
          label: l10n.aboutMeLabel,
          maxLines: 8,
          showCounter: true,
          counterLength: () => controller.actualTextLength,
          counterMax: maxBioLength,
          helperText: l10n.aboutMeHelperText,
          inputFormatters: [
            InlineTokenWireLengthFormatter(
              controller,
              maxWireLength: maxBioLength,
            ),
          ],
          onChanged: (_) => onChanged(),
          onTapOutside: (_) => _bioFocusNode.unfocus(),
          suffixIcon: StarEmojiPickerPopout(
            key: _expressionPickerKey,
            visibleTabs: const [ExpressionPickerTab.emojis],
            onEmojiSelected: (emoji) {
              controller.insertEmoji(
                emoji.name,
                emoji.surrogates,
                maxActualLength: maxBioLength,
              );
              onChanged();
            },
            child: PhosphorIcon(
              PhosphorIconsFill.smiley,
              size: 20,
              color: colors.textTertiary,
            ),
          ),
          onSuffixTap: _onSmileyTap,
        ),
      ),
    );
  }

  Widget _buildUsernameSection(
    UserSettingsViewState state,
    StarLayoutTheme layout,
    StarLocalizations l10n,
  ) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final bool hasCustomDiscriminator = ref.watch(
      instanceFeatureEnabledProvider(LimitKeys.featureCustomDiscriminator),
    );
    final bool uniqueUsernames = ref.watch(uniqueUsernamesProvider);
    final bool shouldShowPremiumCommerce =
        !uniqueUsernames && ref.watch(shouldShowPremiumCommerceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StarFieldLabel(l10n.usernameLabel),
        SizedBox(height: layout.s2),
        Wrap(
          spacing: layout.s2,
          runSpacing: layout.s2,
          children: [
            if (!state.isClaimed)
              StarTooltip(
                message: l10n.claimAccountToChangeStarTag,
                child: StarButton.primary(
                  label: l10n.changeStarTag,
                  size: StarButtonSize.small,
                ),
              )
            else
              StarButton.primary(
                onPressed: () => showStarTagChangeSheet(context),
                label: l10n.changeStarTag,
                size: StarButtonSize.small,
              ),
            if (!hasCustomDiscriminator &&
                shouldShowPremiumCommerce &&
                !isMobileLayout(context))
              StarTooltip(
                message: l10n.customizeTagWithPlutoniumTooltip(
                  state.discriminator,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.brandPrimary,
                    borderRadius: layout.radiusSm,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: layout.s2,
                      vertical: layout.s1_5,
                    ),
                    child: PlutoniumProductIcon(
                      size: 16,
                      color: colors.textOnBrandPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: layout.s3),
        StarHintText(
          uniqueUsernames
              ? l10n.changeYourStarTag
              : l10n.changeUsernameAndTagHint,
        ),
        if (state.premiumDiscriminator &&
            shouldShowPremiumCommerce &&
            !state.hasLifetimePremium) ...[
          SizedBox(height: layout.s2),
          Text(
            l10n.customTagSubscriptionWarning(state.discriminator),
            style: textStyles.bodySmall.copyWith(color: colors.accentWarning),
          ),
        ],
      ],
    );
  }

  Widget _buildAvatarSection(
    UserSettingsViewState state,
    UserSettingsViewModel vm,
    StarLayoutTheme layout,
    StarLocalizations l10n,
  ) {
    final hasAvatar =
        (state.avatarUrl != null || state.editedAvatarBase64 != null) &&
        !state.avatarCleared;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StarFieldLabel(l10n.avatarLabel),
        SizedBox(height: layout.s2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StarButton.primary(
              onPressed: () => _handleImageUpload(isAvatar: true),
              label: l10n.changeAvatar,
              size: StarButtonSize.small,
            ),
            if (hasAvatar) ...[
              SizedBox(height: layout.s2),
              StarButton.secondary(
                onPressed: vm.clearAvatar,
                label: l10n.removeAvatar,
                size: StarButtonSize.small,
              ),
            ],
          ],
        ),
        SizedBox(height: layout.s3),
        StarHintText(
          state.isPremium
              ? l10n.avatarDescription
              : l10n.avatarDescriptionNonPremium,
        ),
      ],
    );
  }

  Widget _buildBannerSection(
    UserSettingsViewState state,
    UserSettingsViewModel vm,
    StarLayoutTheme layout,
    StarLocalizations l10n,
  ) {
    if (!state.isPremium) {
      if (!ref.watch(shouldShowPremiumCommerceProvider)) {
        return const SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StarFieldLabel(l10n.bannerLabel),
          SizedBox(height: layout.s2),
          StarPlutoniumUpsell(
            text: l10n.bannerPlutoniumUpsell,
            buttonSize: StarButtonSize.small,
            onButtonPressed: () =>
                unawaited(openPlutoniumCommerce(context, ref)),
          ),
        ],
      );
    }

    final hasBanner =
        (state.bannerUrl != null || state.editedBannerBase64 != null) &&
        !state.bannerCleared;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StarFieldLabel(l10n.bannerLabel),
        SizedBox(height: layout.s2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StarButton.primary(
              onPressed: () => _handleImageUpload(isAvatar: false),
              label: l10n.changeBanner,
              size: StarButtonSize.small,
            ),
            if (hasBanner) ...[
              SizedBox(height: layout.s2),
              StarButton.secondary(
                onPressed: vm.clearBanner,
                label: l10n.removeBanner,
                size: StarButtonSize.small,
              ),
            ],
          ],
        ),
        SizedBox(height: layout.s3),
        StarHintText(l10n.bannerDescription),
      ],
    );
  }
}
