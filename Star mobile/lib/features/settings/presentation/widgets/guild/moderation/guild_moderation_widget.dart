import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/guilds/services/guild_verification.dart'
    show supportedGuildVerificationLevel;
import 'package:star_app/features/settings/domain/guild/guild_settings_details.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/settings/providers/guild/guild_settings_tab_providers.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart';

const int _contentWarningTextMaxLength = 200;

const Color _verificationLowColor = Color(0xFF22C55E);
const Color _verificationMediumColor = Color(0xFFF59E0B);
const Color _verificationHighColor = Color(0xFFF97316);
const Color _contentFilterMediumColor = Color(0xFFF59E0B);
const Color _contentFilterHighColor = Color(0xFFEF4444);

class GuildModerationWidget extends ConsumerStatefulWidget {
  const GuildModerationWidget({
    required this.guildId,
    required this.details,
    super.key,
    this.scrollController,
  });

  final String guildId;
  final GuildSettingsDetails details;
  final ScrollController? scrollController;

  @override
  ConsumerState<GuildModerationWidget> createState() =>
      _GuildModerationWidgetState();
}

class _GuildModerationWidgetState extends ConsumerState<GuildModerationWidget> {
  late int _verificationLevel;
  late int _explicitContentFilter;
  late int _mfaLevel;
  late bool _nsfw;
  late bool _showContentWarning;
  late final TextEditingController _warningTextController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _applyDetails(widget.details);
    _warningTextController = TextEditingController(
      text: widget.details.contentWarningText ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant GuildModerationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.details != widget.details && !_isDirty) {
      _applyDetails(widget.details);
      _warningTextController.text = widget.details.contentWarningText ?? '';
    }
  }

  void _applyDetails(GuildSettingsDetails details) {
    _verificationLevel = supportedGuildVerificationLevel(
      details.guild.verificationLevel,
    );
    _explicitContentFilter = details.explicitContentFilter;
    _mfaLevel = details.mfaLevel;
    _nsfw = details.guild.nsfw;
    _showContentWarning = details.showContentWarning;
  }

  @override
  void dispose() {
    _warningTextController.dispose();
    super.dispose();
  }

  bool get _isDirty {
    final GuildSettingsDetails details = widget.details;
    return _verificationLevel !=
            supportedGuildVerificationLevel(details.guild.verificationLevel) ||
        _explicitContentFilter != details.explicitContentFilter ||
        _mfaLevel != details.mfaLevel ||
        _nsfw != details.guild.nsfw ||
        _showContentWarning != details.showContentWarning ||
        _warningTextController.text.trim() !=
            (details.contentWarningText ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final bool isDiscoverable = widget.details.guild.isDiscoverable;
    final String? currentUserId = ref.watch(currentUserIdProvider);
    final bool isGuildOwner =
        currentUserId != null && currentUserId == widget.details.guild.ownerId;
    final bool currentUserHas2Fa = ref
        .watch(userSettingsViewModelProvider)
        .mfaEnabled;
    return StarSettingsSheet(
      hasUnsavedChanges: _isDirty,
      isSaving: _isSaving,
      onReset: _reset,
      onSave: _save,
      child: SingleChildScrollView(
        controller: widget.scrollController,
        padding: settingsScrollPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            StarSettingsSection(
              title: l10n.guildSettingsModerationVerificationTitle,
              description: l10n.guildSettingsModerationVerificationDescription,
              isFirst: true,
              children: <Widget>[
                Text(
                  l10n.guildSettingsModerationVerificationRolesBypass,
                  style: context.textStyles.bodySmall.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                if (isDiscoverable)
                  Text(
                    l10n.guildSettingsModerationVerificationDiscoveryNote,
                    style: context.textStyles.bodySmall.copyWith(
                      color: context.colors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                StarRadioGroup<int>(
                  value: _verificationLevel,
                  items: _verificationOptions
                      .map(
                        (_ModerationOption option) => StarRadioItem<int>(
                          value: option.level,
                          label: option.label(l10n),
                          description: option.description(l10n),
                          labelColor: option.labelColor,
                        ),
                      )
                      .toList(),
                  onChanged: (int value) {
                    if (isDiscoverable && value == 0) {
                      return;
                    }
                    setState(() => _verificationLevel = value);
                  },
                ),
              ],
            ),
            StarSettingsSection(
              title: l10n.guildSettingsModerationContentFilterTitle,
              description: l10n.guildSettingsModerationContentFilterDescription,
              children: <Widget>[
                if (isDiscoverable)
                  Text(
                    l10n.guildSettingsModerationContentFilterDiscoveryNote,
                    style: context.textStyles.bodySmall.copyWith(
                      color: context.colors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                StarRadioGroup<int>(
                  value: _explicitContentFilter,
                  items: _contentFilterOptions
                      .map(
                        (_ModerationOption option) => StarRadioItem<int>(
                          value: option.level,
                          label: option.label(l10n),
                          description: option.description(l10n),
                          labelColor: option.labelColor,
                        ),
                      )
                      .toList(),
                  onChanged: (int value) {
                    if (isDiscoverable && value != 2) {
                      return;
                    }
                    setState(() => _explicitContentFilter = value);
                  },
                ),
              ],
            ),
            StarSettingsSection(
              title: l10n.guildSettingsModerationMatureTitle,
              description: l10n.guildSettingsModerationMatureSectionDescription,
              children: <Widget>[
                StarSettingsSwitchItem(
                  label: l10n.guildSettingsModerationMatureToggle,
                  description:
                      l10n.guildSettingsModerationMatureToggleDescription,
                  value: _nsfw,
                  onChanged: (bool value) => setState(() => _nsfw = value),
                ),
                StarSettingsSwitchItem(
                  label: l10n.guildSettingsContentWarningToggle,
                  description:
                      l10n.guildSettingsContentWarningToggleDescription,
                  value: _showContentWarning,
                  onChanged: (bool value) =>
                      setState(() => _showContentWarning = value),
                ),
                if (_showContentWarning)
                  StarInput.multiline(
                    controller: _warningTextController,
                    label: l10n.guildSettingsContentWarningText,
                    hint: l10n.guildSettingsContentWarningTextPlaceholder,
                    maxLength: _contentWarningTextMaxLength,
                    showCounter: true,
                    onChanged: (_) => setState(() {}),
                  ),
              ],
            ),
            if (isGuildOwner)
              StarSettingsSection(
                title: l10n.guildSettingsModeration2faTitle,
                children: <Widget>[
                  _buildMfaSwitch(
                    l10n: l10n,
                    currentUserHas2Fa: currentUserHas2Fa,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMfaSwitch({
    required StarLocalizations l10n,
    required bool currentUserHas2Fa,
  }) {
    final bool isMfaDisabled = !currentUserHas2Fa;
    final String? tooltipText = isMfaDisabled
        ? l10n.guildSettingsModeration2faEnableFirstTooltip
        : null;
    final Widget switchItem = StarSettingsSwitchItem(
      label: l10n.guildSettingsModeration2faSwitchLabel,
      description: l10n.guildSettingsModeration2faDescription,
      value: _mfaLevel == GuildMfaLevel.elevated.json,
      enabled: !isMfaDisabled,
      onChanged: (bool value) => setState(
        () => _mfaLevel = value
            ? GuildMfaLevel.elevated.json!
            : GuildMfaLevel.none.json!,
      ),
    );
    if (tooltipText == null) {
      return switchItem;
    }
    return StarTooltip(message: tooltipText, child: switchItem);
  }

  void _reset() {
    setState(() {
      _applyDetails(widget.details);
      _warningTextController.text = widget.details.contentWarningText ?? '';
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final String? currentUserId = ref.read(currentUserIdProvider);
      final bool isGuildOwner =
          currentUserId != null &&
          currentUserId == widget.details.guild.ownerId;
      final GuildUpdateRequest request = GuildUpdateRequest(
        verificationLevel: GuildVerificationLevelInput.fromJson(
          _verificationLevel,
        ),
        explicitContentFilter: GuildExplicitContentFilterInput.fromJson(
          _explicitContentFilter,
        ),
        nsfw: _nsfw,
        contentWarningLevel: ContentWarningLevelInput.fromJson(
          _showContentWarning ? 1 : 0,
        ),
        contentWarningText: JsonNullable.of(
          _showContentWarning ? _warningTextController.text.trim() : '',
        ),
        mfaLevel: isGuildOwner && _mfaLevel != widget.details.mfaLevel
            ? GuildMfaLevelInput.fromJson(_mfaLevel)
            : null,
      );
      await ref
          .read(guildSettingsModerationActionsProvider(widget.guildId).notifier)
          .updateModeration(request);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _ModerationOption {
  const _ModerationOption(
    this.level,
    this.label,
    this.description, {
    this.labelColor,
  });

  final int level;
  final String Function(StarLocalizations l10n) label;
  final String Function(StarLocalizations l10n) description;
  final Color? labelColor;
}

const List<_ModerationOption> _verificationOptions = <_ModerationOption>[
  _ModerationOption(0, _verificationNoneLabel, _verificationNoneDescription),
  _ModerationOption(
    1,
    _verificationLowLabel,
    _verificationLowDescription,
    labelColor: _verificationLowColor,
  ),
  _ModerationOption(
    2,
    _verificationMediumLabel,
    _verificationMediumDescription,
    labelColor: _verificationMediumColor,
  ),
  _ModerationOption(
    3,
    _verificationHighLabel,
    _verificationHighDescription,
    labelColor: _verificationHighColor,
  ),
];

const List<_ModerationOption> _contentFilterOptions = <_ModerationOption>[
  _ModerationOption(0, _filterOffLabel, _filterOffDescription),
  _ModerationOption(
    1,
    _filterNoRoleLabel,
    _filterNoRoleDescription,
    labelColor: _contentFilterMediumColor,
  ),
  _ModerationOption(
    2,
    _filterAllLabel,
    _filterAllDescription,
    labelColor: _contentFilterHighColor,
  ),
];

String _verificationNoneLabel(StarLocalizations l10n) =>
    l10n.guildSettingsVerificationNone;
String _verificationNoneDescription(StarLocalizations l10n) =>
    l10n.guildSettingsVerificationNoneDescription;
String _verificationLowLabel(StarLocalizations l10n) =>
    l10n.guildSettingsVerificationLow;
String _verificationLowDescription(StarLocalizations l10n) =>
    l10n.guildSettingsVerificationLowDescription;
String _verificationMediumLabel(StarLocalizations l10n) =>
    l10n.guildSettingsVerificationMedium;
String _verificationMediumDescription(StarLocalizations l10n) =>
    l10n.guildSettingsVerificationMediumDescription;
String _verificationHighLabel(StarLocalizations l10n) =>
    l10n.guildSettingsVerificationHigh;
String _verificationHighDescription(StarLocalizations l10n) =>
    l10n.guildSettingsVerificationHighDescription;
String _filterOffLabel(StarLocalizations l10n) =>
    l10n.guildSettingsContentFilterOff;
String _filterOffDescription(StarLocalizations l10n) =>
    l10n.guildSettingsContentFilterOffDescription;
String _filterNoRoleLabel(StarLocalizations l10n) =>
    l10n.guildSettingsContentFilterNoRole;
String _filterNoRoleDescription(StarLocalizations l10n) =>
    l10n.guildSettingsContentFilterNoRoleDescription;
String _filterAllLabel(StarLocalizations l10n) =>
    l10n.guildSettingsContentFilterAll;
String _filterAllDescription(StarLocalizations l10n) =>
    l10n.guildSettingsContentFilterAllDescription;
