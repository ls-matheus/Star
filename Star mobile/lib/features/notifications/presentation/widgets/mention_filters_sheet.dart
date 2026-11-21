import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/notifications/providers/mention_filters_provider.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/toggle_switch/star_switch_control.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

typedef MentionFiltersSheetExtraGroupBuilder =
    Widget Function(BuildContext sheetContext, VoidCallback close);

Future<void> showMentionFiltersSheet(
  BuildContext context, {
  required String title,
  MentionFiltersSheetExtraGroupBuilder? extraGroupBuilder,
}) {
  return StarBottomSheet.show<void>(
    context,
    title: title,
    variant: StarBottomSheetVariant.menu,
    useRootNavigator: true,
    builder: (BuildContext sheetContext, VoidCallback close) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StarBottomSheetGroupColumn(
        children: <Widget>[
          const _MentionFilterSwitches(),
          if (extraGroupBuilder != null) extraGroupBuilder(sheetContext, close),
        ],
      ),
    ),
  );
}

class _MentionFilterSwitches extends ConsumerWidget {
  const _MentionFilterSwitches();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final MentionFilters filters = ref.watch(mentionFiltersPreferencesProvider);
    void apply(MentionFilters next) {
      ref.read(mentionFiltersPreferencesProvider.notifier).set(next);
    }

    return StarMenuGroup(
      children: <Widget>[
        _FilterSwitchRow(
          icon: PhosphorIconsBold.identificationBadge,
          label: l10n.notificationsMentionIncludeRoles,
          value: filters.includeRoles,
          onChanged: (bool value) => apply(
            MentionFilters(
              includeEveryone: filters.includeEveryone,
              includeRoles: value,
              includeGuilds: filters.includeGuilds,
            ),
          ),
        ),
        _FilterSwitchRow(
          icon: PhosphorIconsBold.at,
          label: l10n.notificationsMentionIncludeEveryone,
          value: filters.includeEveryone,
          onChanged: (bool value) => apply(
            MentionFilters(
              includeEveryone: value,
              includeRoles: filters.includeRoles,
              includeGuilds: filters.includeGuilds,
            ),
          ),
        ),
        _FilterSwitchRow(
          icon: PhosphorIconsBold.usersThree,
          label: l10n.notificationsMentionIncludeGuilds,
          value: filters.includeGuilds,
          onChanged: (bool value) => apply(
            MentionFilters(
              includeEveryone: filters.includeEveryone,
              includeRoles: filters.includeRoles,
              includeGuilds: value,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterSwitchRow extends StatelessWidget {
  const _FilterSwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return StarBottomSheetMenuItem(
      icon: icon,
      label: label,
      onTap: () => onChanged(!value),
      trailing: StarSwitchControl(value: value),
    );
  }
}
