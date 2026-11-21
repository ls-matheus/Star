import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/providers/guild/guild_settings_tab_providers.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/utils/snowflake_time.dart';
import 'package:star_app/shared/utils/user_date_formatting.dart';
import 'package:star_dart/export.dart';

Future<void> showGuildMessageHistoryThresholdSheet({
  required BuildContext context,
  required String guildId,
  required DateTime? initialCutoff,
}) {
  return StarBottomSheet.show<void>(
    context,
    title: StarLocalizations.of(
      context,
    ).guildSettingsMessageHistoryThresholdTitle,
    builder: (BuildContext sheetContext, _) =>
        _GuildMessageHistoryThresholdSheet(
          guildId: guildId,
          initialCutoff: initialCutoff,
        ),
  );
}

class _GuildMessageHistoryThresholdSheet extends ConsumerStatefulWidget {
  const _GuildMessageHistoryThresholdSheet({
    required this.guildId,
    required this.initialCutoff,
  });

  final String guildId;
  final DateTime? initialCutoff;

  @override
  ConsumerState<_GuildMessageHistoryThresholdSheet> createState() =>
      _GuildMessageHistoryThresholdSheetState();
}

class _GuildMessageHistoryThresholdSheetState
    extends ConsumerState<_GuildMessageHistoryThresholdSheet> {
  late bool _isEnabled;
  DateTime? _thresholdDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.initialCutoff != null;
    _thresholdDate = widget.initialCutoff?.toLocal();
  }

  DateTime get _guildCreatedAt {
    return dateTimeFromSnowflakeAsLocalOrNow(widget.guildId);
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _thresholdDate ?? now,
      firstDate: _guildCreatedAt,
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _thresholdDate = picked);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final DateTime? cutoff = _isEnabled
          ? (_thresholdDate ?? DateTime.now()).toUtc()
          : null;
      await ref
          .read(guildSettingsOverviewActionsProvider(widget.guildId).notifier)
          .updateGuild(
            GuildUpdateRequest(messageHistoryCutoff: JsonNullable.of(cutoff)),
          );
      if (!mounted ||
          ref
              .read(guildSettingsOverviewActionsProvider(widget.guildId))
              .hasError) {
        return;
      }
      ref
          .read(toastProvider.notifier)
          .show(
            StarToast(
              message: StarLocalizations.of(
                context,
              ).guildSettingsMessageHistoryThresholdUpdated,
            ),
          );
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final String dateLabel = _thresholdDate == null
        ? l10n.guildSettingsMessageHistoryThresholdDate
        : formatUserMediumDate(_thresholdDate!, l10n.localeName);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.layout.s4,
        context.layout.s4,
        context.layout.s4,
        0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          StarSwitchGroup(
            children: <Widget>[
              StarSwitchGroupItem(
                label: l10n.guildSettingsMessageHistoryThresholdEnable,
                value: _isEnabled,
                onChanged: (bool value) => setState(() {
                  _isEnabled = value;
                  if (value && _thresholdDate == null) {
                    _thresholdDate = DateTime.now();
                  }
                }),
              ),
            ],
          ),
          if (_isEnabled) ...<Widget>[
            SizedBox(height: context.layout.s4),
            StarButton.secondary(onPressed: _pickDate, label: dateLabel),
            SizedBox(height: context.layout.s2),
            Text(
              l10n.guildSettingsMessageHistoryThresholdDateHint,
              style: context.textStyles.bodySmall.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
          SizedBox(height: context.layout.s4),
          StarButton.primary(
            onPressed: _isSaving ? null : _save,
            label: l10n.save,
            isLoading: _isSaving,
          ),
        ],
      ),
    );
  }
}
