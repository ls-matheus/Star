import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/profile/presentation/sheets/moderation_duration_labels.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/select/star_select.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class TimeoutMemberSheet {
  TimeoutMemberSheet._();

  static const List<int> _durations = <int>[60, 300, 600, 3600, 86400, 604800];

  static Future<int?> show(BuildContext context, {required String username}) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return StarBottomSheet.show<int>(
      context,
      title: l10n.userProfileTimeoutSheetTitle(username),
      useRootNavigator: true,
      bottomGap: false,
      builder: (sheetContext, close) => const _TimeoutMemberBody(),
    );
  }
}

class _TimeoutMemberBody extends StatefulWidget {
  const _TimeoutMemberBody();

  @override
  State<_TimeoutMemberBody> createState() => _TimeoutMemberBodyState();
}

class _TimeoutMemberBodyState extends State<_TimeoutMemberBody> {
  int _selected = 3600;

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final layout = context.layout;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(layout.s4, 0, layout.s4, layout.s2),
          child: StarSelect<int>(
            label: l10n.userProfileTimeoutDurationLabel,
            value: _selected,
            items: <StarSelectItem<int>>[
              for (final int seconds in TimeoutMemberSheet._durations)
                StarSelectItem<int>(
                  value: seconds,
                  label: durationOptionLabel(l10n, seconds),
                ),
            ],
            enableSearch: false,
            stretch: true,
            onChanged: (int value) => setState(() => _selected = value),
          ),
        ),
        StarBottomSheetFooter(
          child: StarButton.primary(
            label: l10n.userProfileTimeoutSubmit,
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(_selected),
          ),
        ),
      ],
    );
  }
}
