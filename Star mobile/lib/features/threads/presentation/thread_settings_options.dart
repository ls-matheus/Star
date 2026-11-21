import 'package:star_app/features/threads/domain/thread_channel.dart';
import 'package:star_app/features/ui/select/star_select.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';

List<StarSelectItem<int>> threadAutoArchiveItems(StarLocalizations l10n) =>
    <StarSelectItem<int>>[
      for (final int minutes in threadAutoArchiveDurations)
        StarSelectItem<int>(
          value: minutes,
          label: threadAutoArchiveLabel(l10n, minutes),
        ),
    ];
