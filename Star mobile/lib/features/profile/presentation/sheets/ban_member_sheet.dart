import 'package:flutter/services.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/profile/presentation/sheets/moderation_duration_labels.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/input/star_input.dart';
import 'package:star_app/features/ui/select/star_select.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

typedef BanMemberResult = ({
  int deleteMessageDays,
  String? reason,
  int banDurationSeconds,
});

class BanMemberSheet {
  BanMemberSheet._();

  static const int _customSentinel = -1;
  static const int _minCustomSeconds = 60;
  static const int _maxCustomSeconds = 63072000;
  static const List<int> _durations = <int>[
    0,
    3600,
    43200,
    86400,
    259200,
    432000,
    604800,
    1209600,
    2592000,
    _customSentinel,
  ];

  static Future<BanMemberResult?> show(
    BuildContext context, {
    required String username,
  }) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return StarBottomSheet.show<BanMemberResult>(
      context,
      title: l10n.userProfileBanSheetTitle(username),
      useRootNavigator: true,
      bottomGap: false,
      builder: (sheetContext, close) => const _BanMemberBody(),
    );
  }
}

class _BanMemberBody extends StatefulWidget {
  const _BanMemberBody();

  @override
  State<_BanMemberBody> createState() => _BanMemberBodyState();
}

class _BanMemberBodyState extends State<_BanMemberBody> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _customSecondsController =
      TextEditingController();
  int _duration = 0;
  int _deleteDays = 1;

  @override
  void dispose() {
    _reasonController.dispose();
    _customSecondsController.dispose();
    super.dispose();
  }

  int get _resolvedDurationSeconds {
    if (_duration != BanMemberSheet._customSentinel) {
      return _duration;
    }
    final int parsed =
        int.tryParse(_customSecondsController.text.trim()) ??
        BanMemberSheet._minCustomSeconds;
    return parsed.clamp(
      BanMemberSheet._minCustomSeconds,
      BanMemberSheet._maxCustomSeconds,
    );
  }

  void _submit() {
    final String reason = _reasonController.text.trim();
    Navigator.of(context, rootNavigator: true).pop((
      deleteMessageDays: _deleteDays,
      reason: reason.isEmpty ? null : reason,
      banDurationSeconds: _resolvedDurationSeconds,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final layout = context.layout;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(layout.s4, 0, layout.s4, layout.s2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                StarSelect<int>(
                  label: l10n.userProfileBanDurationLabel,
                  value: _duration,
                  items: <StarSelectItem<int>>[
                    for (final int seconds in BanMemberSheet._durations)
                      StarSelectItem<int>(
                        value: seconds,
                        label: seconds == BanMemberSheet._customSentinel
                            ? l10n.durationCustom
                            : durationOptionLabel(l10n, seconds),
                      ),
                  ],
                  enableSearch: false,
                  stretch: true,
                  scrollableSheet: true,
                  onChanged: (int value) => setState(() => _duration = value),
                ),
                if (_duration == BanMemberSheet._customSentinel) ...<Widget>[
                  SizedBox(height: layout.s3),
                  StarInput(
                    controller: _customSecondsController,
                    label: l10n.userProfileBanCustomSecondsLabel,
                    helperText: l10n.userProfileBanCustomSecondsHelper(
                      BanMemberSheet._minCustomSeconds,
                      BanMemberSheet._maxCustomSeconds,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ],
                SizedBox(height: layout.s3),
                StarSelect<int>(
                  label: l10n.userProfileBanDeleteHistoryLabel,
                  value: _deleteDays,
                  items: <StarSelectItem<int>>[
                    StarSelectItem<int>(
                      value: 0,
                      label: l10n.userProfileBanDeleteNone,
                    ),
                    StarSelectItem<int>(
                      value: 1,
                      label: l10n.userProfileBanDelete24h,
                    ),
                    StarSelectItem<int>(
                      value: 7,
                      label: l10n.userProfileBanDelete7d,
                    ),
                  ],
                  enableSearch: false,
                  stretch: true,
                  onChanged: (int value) => setState(() => _deleteDays = value),
                ),
                SizedBox(height: layout.s3),
                StarInput.multiline(
                  controller: _reasonController,
                  textCapitalization: TextCapitalization.sentences,
                  label: l10n.userProfileBanReasonLabel,
                  hint: l10n.userProfileBanReasonHint,
                  maxLength: 512,
                  showCounter: true,
                ),
              ],
            ),
          ),
        ),
        StarBottomSheetFooter(
          child: StarButton.dangerPrimary(
            label: l10n.userProfileBanSubmit,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}
