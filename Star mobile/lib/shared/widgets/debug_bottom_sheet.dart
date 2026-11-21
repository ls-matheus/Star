import 'dart:async';
import 'dart:convert';

import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/utils/clipboard_utils.dart';

Future<void> showDebugBottomSheet(
  BuildContext context, {
  required String title,
  required Map<String, Object?> data,
  String? copiedMessage,
}) {
  final String json = const JsonEncoder.withIndent('  ').convert(data);
  return StarBottomSheet.showScrollable<void>(
    context,
    title: title,
    minChildSize: 0.5,
    builder: (sheetContext, scrollController, close) => _DebugSheetBody(
      json: json,
      copiedMessage: copiedMessage,
      scrollController: scrollController,
    ),
  );
}

class _DebugSheetBody extends StatelessWidget {
  const _DebugSheetBody({
    required this.json,
    required this.copiedMessage,
    required this.scrollController,
  });

  final String json;
  final String? copiedMessage;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = StarLocalizations.of(context);
    final colors = context.colors;
    final layout = context.layout;

    return SingleChildScrollView(
      controller: scrollController,
      padding: StarBottomSheet.scrollViewPadding(
        context,
        padding: EdgeInsets.symmetric(horizontal: layout.s4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          StarMenuGroup(
            children: [
              StarBottomSheetMenuItem(
                icon: PhosphorIconsFill.copy,
                label: l10n.chatMessageDebugCopyJson,
                onTap: () {
                  unawaited(
                    copyToClipboard(
                      context: context,
                      value: json,
                      message: copiedMessage,
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: layout.s3),
          Container(
            padding: EdgeInsets.all(layout.s3),
            decoration: BoxDecoration(
              color: StarBottomSheet.cardColorOf(context),
              borderRadius: layout.radiusLg,
            ),
            child: SelectableText(
              json,
              style: context.textStyles.codeText.copyWith(
                fontSize: 12,
                height: 1.4,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
