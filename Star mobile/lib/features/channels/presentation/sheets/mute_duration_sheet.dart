import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart';
import 'package:intl/intl.dart';

class MuteSelection {
  const MuteSelection({this.durationSeconds});

  final int? durationSeconds;
}

const List<int> kMuteDurationsSeconds = <int>[
  900,
  1800,
  3600,
  10800,
  14400,
  28800,
  86400,
  259200,
];

String muteDurationLabel(int seconds, StarLocalizations l10n) {
  return switch (seconds) {
    900 => l10n.dmMuteFor15Min,
    1800 => l10n.dmMuteFor30Min,
    3600 => l10n.dmMuteFor1Hour,
    10800 => l10n.dmMuteFor3Hours,
    14400 => l10n.dmMuteFor4Hours,
    28800 => l10n.dmMuteFor8Hours,
    86400 => l10n.dmMuteFor24Hours,
    259200 => l10n.dmMuteFor3Days,
    _ => throw ArgumentError.value(seconds, 'seconds'),
  };
}

String? formatMutedHintText(
  ChannelOverridesMuteConfig? config,
  StarLocalizations l10n,
) {
  if (config == null) {
    return null;
  }
  final Object? endTimeValue = config.endTime;
  final String? endTimeStr = endTimeValue is String ? endTimeValue : null;
  if (endTimeStr == null) {
    return l10n.channelMutedHint;
  }
  final end = DateTime.tryParse(endTimeStr)?.toLocal();
  if (end == null) {
    return l10n.channelMutedHint;
  }
  return l10n.guildNavbarMutedUntil(
    DateFormat.yMMMd(l10n.localeName).add_jm().format(end),
  );
}

class MuteDurationSheetBody extends StatelessWidget {
  const MuteDurationSheetBody({required this.onSelected, super.key});

  final ValueChanged<MuteSelection> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = StarLocalizations.of(context);

    return StarBottomSheetGroupColumn(
      children: [
        StarMenuGroup(
          children: [
            for (final seconds in kMuteDurationsSeconds)
              StarBottomSheetMenuItem(
                label: muteDurationLabel(seconds, l10n),
                onTap: () =>
                    onSelected(MuteSelection(durationSeconds: seconds)),
              ),
            StarBottomSheetMenuItem(
              label: l10n.dmMuteForever,
              onTap: () => onSelected(const MuteSelection()),
            ),
          ],
        ),
      ],
    );
  }
}

Future<MuteSelection?> showMuteDurationSheet(
  BuildContext context, {
  required String muteTitle,
  bool useRootNavigator = false,
}) {
  return StarBottomSheet.show<MuteSelection>(
    context,
    title: muteTitle,
    variant: StarBottomSheetVariant.menu,
    useRootNavigator: useRootNavigator,
    builder: (sheetContext, _) => StarBottomSheetContent(
      child: MuteDurationSheetBody(
        onSelected: (selection) => Navigator.of(sheetContext).pop(selection),
      ),
    ),
  );
}
