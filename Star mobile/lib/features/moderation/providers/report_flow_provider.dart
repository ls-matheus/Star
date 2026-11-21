import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/features/moderation/data/report_flow_repository.dart';
import 'package:star_app/features/moderation/domain/report_flow.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'report_flow_provider.g.dart';

@Riverpod(keepAlive: true)
ReportFlowRepository reportFlowRepository(Ref ref) {
  return ReportFlowRepository(ref.watch(starDioProvider));
}

Duration? _noRetry(int retryCount, Object error) => null;

@Riverpod(retry: _noRetry)
Future<ReportFlow> reportFlow(
  Ref ref, {
  required ReportFlowTargetType targetType,
  required String locale,
}) async {
  final ReportFlow flow = await ref
      .watch(reportFlowRepositoryProvider)
      .fetch(targetType, locale: locale);
  ref.keepAlive();
  return flow;
}
