import 'package:dio/dio.dart';
import 'package:star_app/core/build/app_build_config.dart';
import 'package:star_app/core/observability/star_measure_dio_interceptor.dart';
import 'package:star_app/core/observability/star_measure_http.dart';

void attachStarMeasureDioInterceptor(
  Dio dio, {
  required StarMeasureHttpTrackingGate shouldTrackRequest,
}) {
  if (!AppBuildConfig.hasObservabilityConfig) {
    return;
  }
  dio.interceptors.add(
    StarMeasureDioInterceptor(shouldTrackRequest: shouldTrackRequest),
  );
}
