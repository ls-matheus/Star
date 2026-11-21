import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/app/local_day_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/utils/relative_time.dart';

class DmRowTimestamp extends ConsumerWidget {
  const DmRowTimestamp({required this.time, required this.style, super.key});

  final DateTime time;
  final TextStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(relativeTimeTickProvider);
    return Text(
      relativeTimeShort(
        time,
        StarLocalizations.of(context),
        minimumOneMinute: true,
      ),
      style: style,
      maxLines: 1,
    );
  }
}
