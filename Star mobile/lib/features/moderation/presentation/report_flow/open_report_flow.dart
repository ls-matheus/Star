import 'package:star_app/features/moderation/domain/iar_context.dart';
import 'package:star_app/features/moderation/presentation/report_flow/report_flow_sheet.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/material_ui.dart';

Future<void> openReportFlow(
  BuildContext context, {
  required IarContext iarContext,
}) {
  return StarBottomSheet.show<void>(
    context,
    bottomGap: false,
    builder: (sheetContext, close) =>
        ReportFlowSheet(target: iarContext, close: close),
  );
}
