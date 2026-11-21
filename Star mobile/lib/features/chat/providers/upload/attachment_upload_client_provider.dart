import 'package:dio/dio.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/observability/star_measure_dio.dart';
import 'package:star_app/core/observability/measure_http_policy.dart';
import 'package:star_app/features/chat/data/attachment_upload_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'attachment_upload_client_provider.g.dart';

@Riverpod(keepAlive: true)
AttachmentUploadClient attachmentUploadClient(Ref ref) {
  return AttachmentUploadClient(
    apiDio: ref.watch(starDioProvider),
    uploadDio: ref.watch(attachmentUploadDioProvider),
  );
}

@Riverpod(keepAlive: true)
Dio attachmentUploadDio(Ref ref) {
  final Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(minutes: 10),
      receiveTimeout: const Duration(minutes: 10),
      validateStatus: (int? status) =>
          status != null && status >= 200 && status < 300,
    ),
  );
  attachStarMeasureDioInterceptor(
    dio,
    shouldTrackRequest: (Uri uri) => kMeasureHttpPolicy.shouldTrackHttpRequest(
      instance: ref.read(activeInstanceProvider),
      requestUri: uri,
    ),
  );
  ref.onDispose(dio.close);
  return dio;
}
