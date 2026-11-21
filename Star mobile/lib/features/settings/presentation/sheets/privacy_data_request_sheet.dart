import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/app/account_user_id.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/guilds/domain/guild.dart';
import 'package:star_app/features/guilds/providers/guild_list_view_model.dart';
import 'package:star_app/features/settings/domain/privacy_data_request.dart';
import 'package:star_app/features/settings/providers/view_models/privacy_dashboard_view_model.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/utils/user_date_formatting.dart';

class PrivacyDataRequestSheet extends ConsumerStatefulWidget {
  const PrivacyDataRequestSheet({
    required this.variant,
    required this.onClose,
    super.key,
  });

  final PrivacyDataRequestVariant variant;
  final VoidCallback onClose;

  static Future<void> show(
    BuildContext context, {
    required PrivacyDataRequestVariant variant,
  }) {
    final l10n = StarLocalizations.of(context);
    final title = variant == PrivacyDataRequestVariant.export
        ? l10n.privacyDashboardDataRequestExportTitle
        : l10n.privacyDashboardDataRequestDeleteTitle;

    return StarBottomSheet.showScrollable<void>(
      context,
      title: title,
      useRootNavigator: true,
      initialChildSize: StarBottomSheet.scrollableSheetHalfSize,
      builder: (sheetContext, scrollController, close) {
        return PrivacyDataRequestSheet(variant: variant, onClose: close);
      },
    );
  }

  @override
  ConsumerState<PrivacyDataRequestSheet> createState() =>
      _PrivacyDataRequestSheetState();
}

class _PrivacyDataRequestSheetState
    extends ConsumerState<PrivacyDataRequestSheet> {
  late PrivacyDataRequestStep _step;
  late PrivacyDataRequestFilterState _filter;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _filter = PrivacyDataRequestFilterState.initial(widget.variant);
    _step = PrivacyDataRequestStep.scope;
  }

  bool get _isExport => widget.variant == PrivacyDataRequestVariant.export;

  List<PrivacyDataRequestStep> get _visibleSteps =>
      _filter.visibleSteps(widget.variant);

  int get _currentStepIndex =>
      _visibleSteps.indexOf(_step).clamp(0, _visibleSteps.length - 1);

  bool get _isLastStep => _step == PrivacyDataRequestStep.confirm;

  String? get _needsInclusion {
    if (!_filter.isCustomScope(widget.variant)) {
      return null;
    }
    if (_filter.includeDms ||
        _filter.includeDmsClosed ||
        _filter.includeGroupDms ||
        _filter.includeGuilds) {
      return null;
    }
    return StarLocalizations.of(
      context,
    ).privacyDashboardDataRequestNeedInclusion;
  }

  String? get _dateRangeError {
    if (_filter.dateMode != PrivacyDataRequestDateMode.custom ||
        _filter.startDate == null ||
        _filter.endDate == null) {
      return null;
    }
    if (!_filter.startDate!.isBefore(_filter.endDate!)) {
      return StarLocalizations.of(
        context,
      ).privacyDashboardDataRequestDateRangeError;
    }
    return null;
  }

  bool get _canContinue {
    switch (_step) {
      case PrivacyDataRequestStep.scope:
        return true;
      case PrivacyDataRequestStep.kinds:
        return _needsInclusion == null;
      case PrivacyDataRequestStep.communities:
        return true;
      case PrivacyDataRequestStep.when:
        return _dateRangeError == null;
      case PrivacyDataRequestStep.confirm:
        return !_isSubmitting;
    }
  }

  void _goBack() {
    final int index = _currentStepIndex;
    if (index > 0) {
      setState(() => _step = _visibleSteps[index - 1]);
    } else {
      widget.onClose();
    }
  }

  void _goNext() {
    final int index = _currentStepIndex;
    if (index < _visibleSteps.length - 1) {
      setState(() => _step = _visibleSteps[index + 1]);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);
    final vm = ref.read(
      privacyDashboardViewModelProvider(readAccountUserId(ref)).notifier,
    );
    final l10n = StarLocalizations.of(context);
    final bool success;
    if (_isExport) {
      if (_filter.scope == PrivacyDataRequestScope.everything) {
        success = await vm.requestFullDataExport();
      } else {
        success = await vm.requestFilteredDataExport(
          _filter.toHarvestRequest(),
        );
      }
    } else {
      success = await vm.bulkDeleteMessages(_filter.toDeleteRequest());
    }
    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);
    if (success) {
      ref
          .read(toastProvider.notifier)
          .show(
            StarToast(
              message: _isExport
                  ? l10n.privacyDashboardDataRequestExportSuccess
                  : l10n.privacyDashboardDataRequestDeleteSuccess,
              variant: StarToastVariant.success,
            ),
          );
      widget.onClose();
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          (isStart ? _filter.startDate : _filter.endDate) ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _filter = isStart
            ? _filter.copyWith(startDate: picked)
            : _filter.copyWith(endDate: picked);
      });
    }
  }

  String _formatSummaryDate(DateTime date) {
    return formatUserMediumDate(
      date,
      StarLocalizations.of(context).localeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = StarLocalizations.of(context);
    final colors = context.colors;
    final layout = context.layout;
    final guilds = ref.watch(guildListViewModelProvider).guilds.toList()
      ..sort((Guild a, Guild b) => a.name.compareTo(b.name));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: StarBottomSheet.scrollViewPadding(
              context,
              padding: EdgeInsets.symmetric(horizontal: layout.s4),
            ),
            children: [
              switch (_step) {
                PrivacyDataRequestStep.scope => _buildScopeStep(l10n),
                PrivacyDataRequestStep.kinds => _buildKindsStep(l10n, colors),
                PrivacyDataRequestStep.communities => _buildCommunitiesStep(
                  l10n,
                  colors,
                  layout,
                  guilds,
                ),
                PrivacyDataRequestStep.when => _buildWhenStep(
                  l10n,
                  colors,
                  layout,
                ),
                PrivacyDataRequestStep.confirm => _buildConfirmStep(
                  l10n,
                  colors,
                  layout,
                ),
              },
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            layout.s4,
            layout.s2,
            layout.s4,
            StarBottomSheet.scrollBottomPaddingOf(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isLastStep)
                StarButton.primary(
                  label: _isExport
                      ? l10n.privacyDashboardDataRequestRequestExport
                      : l10n.privacyDashboardDataRequestDeleteMessages,
                  isLoading: _isSubmitting,
                  onPressedAsync: _canContinue ? _submit : null,
                )
              else
                StarButton.primary(
                  label: l10n.continueAction,
                  onPressed: _canContinue ? _goNext : null,
                ),
              SizedBox(height: layout.s2),
              StarButton.secondary(
                label: _currentStepIndex == 0
                    ? l10n.cancel
                    : l10n.privacyDashboardDataRequestGoBack,
                onPressed: _isSubmitting ? null : _goBack,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScopeStep(StarLocalizations l10n) {
    final List<StarRadioItem<PrivacyDataRequestScope>> items;
    if (_isExport) {
      items = [
        StarRadioItem(
          value: PrivacyDataRequestScope.everything,
          label: l10n.privacyDashboardDataRequestExportEverything,
          description: l10n.privacyDashboardDataRequestExportEverythingDesc,
        ),
        StarRadioItem(
          value: PrivacyDataRequestScope.custom,
          label: l10n.privacyDashboardDataRequestExportCustom,
          description: l10n.privacyDashboardDataRequestExportCustomDesc,
        ),
      ];
    } else {
      items = [
        StarRadioItem(
          value: PrivacyDataRequestScope.selected,
          label: l10n.privacyDashboardDataRequestDeleteSelected,
          description: l10n.privacyDashboardDataRequestDeleteSelectedDesc,
        ),
        StarRadioItem(
          value: PrivacyDataRequestScope.inaccessibleOnly,
          label: l10n.privacyDashboardDataRequestDeleteInaccessible,
          description: l10n.privacyDashboardDataRequestDeleteInaccessibleDesc,
        ),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.privacyDashboardDataRequestScopeTitle,
          style: context.textStyles.heading,
        ),
        SizedBox(height: context.layout.s3),
        StarRadioGroup<PrivacyDataRequestScope>(
          value: _filter.scope,
          items: items,
          onChanged: (value) =>
              setState(() => _filter = _filter.copyWith(scope: value)),
        ),
      ],
    );
  }

  Widget _buildKindsStep(StarLocalizations l10n, StarColorTheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.privacyDashboardDataRequestKindsTitle,
          style: context.textStyles.heading,
        ),
        SizedBox(height: context.layout.s2),
        Text(
          l10n.privacyDashboardDataRequestKindsBody,
          style: context.textStyles.bodySmall.copyWith(
            color: colors.textPrimaryMuted,
          ),
        ),
        SizedBox(height: context.layout.s3),
        StarSettingsSwitchGroup(
          children: [
            StarSettingsSwitchItem.grouped(
              label: l10n.privacyDashboardDataRequestKindDms,
              value: _filter.includeDms,
              onChanged: (value) =>
                  setState(() => _filter = _filter.copyWith(includeDms: value)),
            ),
            StarSettingsSwitchItem.grouped(
              label: l10n.privacyDashboardDataRequestKindDmsClosed,
              value: _filter.includeDmsClosed,
              onChanged: (value) => setState(
                () => _filter = _filter.copyWith(includeDmsClosed: value),
              ),
            ),
            StarSettingsSwitchItem.grouped(
              label: l10n.privacyDashboardDataRequestKindGroupDms,
              value: _filter.includeGroupDms,
              onChanged: (value) => setState(
                () => _filter = _filter.copyWith(includeGroupDms: value),
              ),
            ),
            StarSettingsSwitchItem.grouped(
              label: l10n.privacyDashboardDataRequestKindCommunities,
              value: _filter.includeGuilds,
              onChanged: (value) => setState(
                () => _filter = _filter.copyWith(includeGuilds: value),
              ),
            ),
          ],
        ),
        if (_needsInclusion != null) ...[
          SizedBox(height: context.layout.s2),
          Text(
            _needsInclusion!,
            style: context.textStyles.bodySmall.copyWith(
              color: colors.statusDanger,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCommunitiesStep(
    StarLocalizations l10n,
    StarColorTheme colors,
    StarLayoutTheme layout,
    List<Guild> guilds,
  ) {
    final bool isExclude =
        _filter.guildFilterMode == PrivacyDataRequestGuildFilterMode.exclude;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.privacyDashboardDataRequestCommunitiesTitle,
          style: context.textStyles.heading,
        ),
        SizedBox(height: layout.s3),
        StarSelect<PrivacyDataRequestGuildFilterMode>(
          label: l10n.privacyDashboardDataRequestGuildFilterMode,
          value: _filter.guildFilterMode,
          enableSearch: false,
          items: [
            StarSelectItem(
              value: PrivacyDataRequestGuildFilterMode.exclude,
              label: l10n.privacyDashboardDataRequestGuildFilterExclude,
            ),
            StarSelectItem(
              value: PrivacyDataRequestGuildFilterMode.includeOnly,
              label: l10n.privacyDashboardDataRequestGuildFilterInclude,
            ),
          ],
          onChanged: (value) => setState(
            () => _filter = _filter.copyWith(guildFilterMode: value),
          ),
        ),
        SizedBox(height: layout.s3),
        if (guilds.isEmpty)
          Text(
            l10n.privacyDashboardDataRequestCommunitiesEmpty,
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textPrimaryMuted,
            ),
          )
        else
          StarSettingsSwitchGroup(
            children: guilds.map((Guild guild) {
              final bool isOn = isExclude
                  ? _filter.excludedGuildIds.contains(guild.id)
                  : _filter.includedGuildIds.contains(guild.id);
              return StarSettingsSwitchItem.grouped(
                label: guild.name,
                value: isOn,
                onChanged: (value) {
                  setState(() {
                    if (isExclude) {
                      final ids = Set<String>.from(_filter.excludedGuildIds);
                      if (value) {
                        ids.add(guild.id);
                      } else {
                        ids.remove(guild.id);
                      }
                      _filter = _filter.copyWith(excludedGuildIds: ids);
                    } else {
                      final ids = Set<String>.from(_filter.includedGuildIds);
                      if (value) {
                        ids.add(guild.id);
                      } else {
                        ids.remove(guild.id);
                      }
                      _filter = _filter.copyWith(includedGuildIds: ids);
                    }
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildWhenStep(
    StarLocalizations l10n,
    StarColorTheme colors,
    StarLayoutTheme layout,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.privacyDashboardDataRequestWhenTitle,
          style: context.textStyles.heading,
        ),
        SizedBox(height: layout.s3),
        StarSelect<PrivacyDataRequestDateMode>(
          label: l10n.privacyDashboardDataRequestDateMode,
          value: _filter.dateMode,
          enableSearch: false,
          items: [
            StarSelectItem(
              value: PrivacyDataRequestDateMode.allTime,
              label: l10n.privacyDashboardDataRequestAllTime,
            ),
            StarSelectItem(
              value: PrivacyDataRequestDateMode.custom,
              label: l10n.privacyDashboardDataRequestCustomRange,
            ),
          ],
          onChanged: (value) =>
              setState(() => _filter = _filter.copyWith(dateMode: value)),
        ),
        if (_filter.dateMode == PrivacyDataRequestDateMode.custom) ...[
          SizedBox(height: layout.s3),
          _DateField(
            label: l10n.privacyDashboardDataRequestStartDate,
            value: _filter.startDate,
            onTap: () => unawaited(_pickDate(isStart: true)),
          ),
          SizedBox(height: layout.s2),
          _DateField(
            label: l10n.privacyDashboardDataRequestEndDate,
            value: _filter.endDate,
            onTap: () => unawaited(_pickDate(isStart: false)),
          ),
          SizedBox(height: layout.s2),
          Text(
            l10n.privacyDashboardDataRequestDateHelper,
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textPrimaryMuted,
            ),
          ),
          if (_dateRangeError != null) ...[
            SizedBox(height: layout.s2),
            Text(
              _dateRangeError!,
              style: context.textStyles.bodySmall.copyWith(
                color: colors.statusDanger,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildConfirmStep(
    StarLocalizations l10n,
    StarColorTheme colors,
    StarLayoutTheme layout,
  ) {
    final String body;
    if (_isExport) {
      body = _filter.scope == PrivacyDataRequestScope.everything
          ? l10n.privacyDashboardDataRequestExportConfirmEverything
          : l10n.privacyDashboardDataRequestExportConfirmCustom;
    } else {
      body = l10n.privacyDashboardDataRequestDeleteConfirm;
    }

    final String scopeLabel = switch (_filter.scope) {
      PrivacyDataRequestScope.everything =>
        l10n.privacyDashboardDataRequestExportEverything,
      PrivacyDataRequestScope.custom =>
        l10n.privacyDashboardDataRequestExportCustom,
      PrivacyDataRequestScope.selected =>
        l10n.privacyDashboardDataRequestDeleteSelected,
      PrivacyDataRequestScope.inaccessibleOnly =>
        l10n.privacyDashboardDataRequestDeleteInaccessible,
    };

    final List<String> conversationParts = <String>[];
    if (_filter.isCustomScope(widget.variant)) {
      if (_filter.includeDms && _filter.includeDmsClosed) {
        conversationParts.add(l10n.privacyDashboardDataRequestSummaryDmsBoth);
      } else if (_filter.includeDms) {
        conversationParts.add(l10n.privacyDashboardDataRequestSummaryDmsOpen);
      } else if (_filter.includeDmsClosed) {
        conversationParts.add(l10n.privacyDashboardDataRequestSummaryDmsClosed);
      }
      if (_filter.includeGroupDms) {
        conversationParts.add(l10n.privacyDashboardDataRequestSummaryGroupDms);
      }
      if (_filter.includeGuilds) {
        conversationParts.add(
          l10n.privacyDashboardDataRequestSummaryCommunitiesIncluded,
        );
      }
    }

    final String conversationsValue = conversationParts.isEmpty
        ? l10n.privacyDashboardDataRequestSummaryNone
        : conversationParts.join(', ');

    final int communityCount =
        _filter.guildFilterMode == PrivacyDataRequestGuildFilterMode.exclude
        ? _filter.excludedGuildIds.length
        : _filter.includedGuildIds.length;
    final String communitiesValue =
        _filter.guildFilterMode == PrivacyDataRequestGuildFilterMode.exclude
        ? l10n.privacyDashboardDataRequestSummaryGuildExclude(communityCount)
        : l10n.privacyDashboardDataRequestSummaryGuildInclude(communityCount);

    final String timeRangeValue;
    if (_filter.dateMode == PrivacyDataRequestDateMode.allTime) {
      timeRangeValue = l10n.privacyDashboardDataRequestAllTime;
    } else if (_filter.startDate != null && _filter.endDate != null) {
      timeRangeValue = l10n.privacyDashboardDataRequestSummaryBetween(
        _formatSummaryDate(_filter.startDate!),
        _formatSummaryDate(_filter.endDate!),
      );
    } else if (_filter.startDate != null) {
      timeRangeValue = l10n.privacyDashboardDataRequestSummaryFrom(
        _formatSummaryDate(_filter.startDate!),
      );
    } else if (_filter.endDate != null) {
      timeRangeValue = l10n.privacyDashboardDataRequestSummaryUntil(
        _formatSummaryDate(_filter.endDate!),
      );
    } else {
      timeRangeValue = l10n.privacyDashboardDataRequestAllTime;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.privacyDashboardDataRequestConfirmTitle,
          style: context.textStyles.heading,
        ),
        SizedBox(height: layout.s2),
        Text(
          body,
          style: context.textStyles.bodySmall.copyWith(
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: layout.s3),
        _SummaryRow(
          label: l10n.privacyDashboardDataRequestSummaryScope,
          value: scopeLabel,
        ),
        if (_filter.isCustomScope(widget.variant)) ...[
          SizedBox(height: layout.s2),
          _SummaryRow(
            label: l10n.privacyDashboardDataRequestSummaryConversations,
            value: conversationsValue,
          ),
        ],
        if (_filter.showCommunities(widget.variant)) ...[
          SizedBox(height: layout.s2),
          _SummaryRow(
            label: l10n.privacyDashboardDataRequestSummaryCommunities,
            value: communitiesValue,
          ),
        ],
        if (_filter.showWhen(widget.variant)) ...[
          SizedBox(height: layout.s2),
          _SummaryRow(
            label: l10n.privacyDashboardDataRequestSummaryTimeRange,
            value: timeRangeValue,
          ),
        ],
        if (!_isExport) ...[
          SizedBox(height: layout.s3),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: StarBottomSheet.cardColorOf(context),
              border: Border.all(color: colors.backgroundHeaderSecondary),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: EdgeInsets.all(layout.s3),
            child: Text(
              l10n.privacyDashboardDataRequestDeleteDanger,
              style: context.textStyles.bodySmall.copyWith(
                color: colors.statusDanger,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final String display = value == null
        ? '—'
        : formatUserMediumDate(
            value!,
            StarLocalizations.of(context).localeName,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textStyles.bodySmall.copyWith(
            color: colors.textPrimaryMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: context.layout.s1),
        StarButton.secondary(label: display, onPressed: onTap),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textPrimaryMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
