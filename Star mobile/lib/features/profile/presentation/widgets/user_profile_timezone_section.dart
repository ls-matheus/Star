import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/profile/utils/profile_timezone_utils.dart';
import 'package:star_app/features/settings/providers/preferences/time_format_providers.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class UserProfileTimezoneSection extends ConsumerStatefulWidget {
  const UserProfileTimezoneSection({
    required this.timezoneOffset,
    this.compact = false,
    super.key,
  });

  final int timezoneOffset;
  final bool compact;

  @override
  ConsumerState<UserProfileTimezoneSection> createState() =>
      _UserProfileTimezoneSectionState();
}

class _UserProfileTimezoneSectionState
    extends ConsumerState<UserProfileTimezoneSection> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final l10n = StarLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final String localTime = formatProfileLocalTime(
      now: _now,
      offsetMinutes: widget.timezoneOffset,
      locale: locale,
      use12Hour: ref.watch(use12HourTimeFormatProvider),
    );
    final String differenceText = formatTimezoneDifferenceText(
      l10n: l10n,
      profileOffsetMinutes: widget.timezoneOffset,
      viewerOffsetMinutes: getViewerOffsetMinutes(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: <Widget>[
        Text(
          l10n.userProfileLocalTime,
          style: textStyles.label.copyWith(
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: widget.compact ? 20 / 14 : 1.25,
          ),
        ),
        Text(
          localTime,
          style: textStyles.bodySmall.copyWith(
            color: colors.textChat,
            fontSize: 14,
            height: widget.compact ? 20 / 14 : 1.25,
          ),
        ),
        Text(
          differenceText,
          style: textStyles.bodySmall.copyWith(
            color: colors.textTertiary,
            fontSize: 12,
            height: widget.compact ? 16 / 12 : 1,
          ),
        ),
      ],
    );
  }
}
