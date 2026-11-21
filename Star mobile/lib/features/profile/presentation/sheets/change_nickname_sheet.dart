import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/input/star_input.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

typedef ChangeNicknameResult = ({String? nick});

class ChangeNicknameSheet {
  ChangeNicknameSheet._();

  static Future<ChangeNicknameResult?> show(
    BuildContext context, {
    required String username,
    required String? currentNick,
  }) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return StarBottomSheet.show<ChangeNicknameResult>(
      context,
      title: l10n.userProfileChangeNickname,
      useRootNavigator: true,
      bottomGap: false,
      builder: (sheetContext, close) =>
          _ChangeNicknameBody(currentNick: currentNick),
    );
  }
}

class _ChangeNicknameBody extends StatefulWidget {
  const _ChangeNicknameBody({required this.currentNick});

  final String? currentNick;

  @override
  State<_ChangeNicknameBody> createState() => _ChangeNicknameBodyState();
}

class _ChangeNicknameBodyState extends State<_ChangeNicknameBody> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.currentNick ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final String nick = _controller.text.trim();
    Navigator.of(
      context,
      rootNavigator: true,
    ).pop((nick: nick.isEmpty ? null : nick));
  }

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final layout = context.layout;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(layout.s4, 0, layout.s4, layout.s2),
          child: StarInput(
            controller: _controller,
            label: l10n.userProfileNicknameLabel,
            hint: l10n.userProfileNicknameHint,
            maxLength: 32,
            showCounter: true,
            autofocus: true,
            onSubmitted: (_) => _save(),
          ),
        ),
        StarBottomSheetFooter(
          child: StarButton.primary(
            label: l10n.userProfileNicknameSave,
            onPressed: _save,
          ),
        ),
      ],
    );
  }
}
