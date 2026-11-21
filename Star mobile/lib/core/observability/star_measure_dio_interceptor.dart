import 'dart:collection';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:star_app/core/observability/star_measure_http.dart';
import 'package:star_app/core/observability/star_observability.dart';
import 'package:star_app/core/observability/measure_log_redaction.dart';
import 'package:measure_flutter/measure_flutter.dart';

class StarMeasureDioInterceptor extends Interceptor {
  final HashMap<RequestOptions, int> _requestsStartTime =
      HashMap<RequestOptions, int>();
  final MeasureApi _measure;
  final StarMeasureHttpTrackingGate _shouldTrackRequest;

  StarMeasureDioInterceptor({required this._shouldTrackRequest})
    : _measure = Measure.instance;

  @visibleForTesting
  StarMeasureDioInterceptor.withMeasure(
    this._measure, {
    required this._shouldTrackRequest,
  });

  bool _mayTrack(RequestOptions request) {
    if (!StarObservability.instance.isEnabled) {
      return false;
    }
    return _shouldTrackRequest(request.uri);
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_mayTrack(options)) {
      _requestsStartTime[options] = Measure.instance.getCurrentTime();
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final RequestOptions request = response.requestOptions;
    if (!_mayTrack(request)) {
      handler.next(response);
      _requestsStartTime.remove(request);
      return;
    }
    final String rawUrl = request.uri.toString();
    if (!_measure.shouldTrackHttpEvent(rawUrl)) {
      handler.next(response);
      _requestsStartTime.remove(request);
      return;
    }

    try {
      final int? startTime = _requestsStartTime[request];
      if (startTime != null) {
        trackStarMeasureHttpEvent(
          measure: _measure,
          url: redactMeasureHttpUrl(rawUrl),
          method: _method(request),
          startTime: startTime,
          endTime: Measure.instance.getCurrentTime(),
          statusCode: response.statusCode,
        );
      }
    } on Object catch (e, stacktrace) {
      _logInternalError(e, stacktrace);
    } finally {
      handler.next(response);
      _requestsStartTime.remove(request);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final RequestOptions request = err.requestOptions;
    if (!_mayTrack(request)) {
      handler.next(err);
      _requestsStartTime.remove(request);
      return;
    }
    final String rawUrl = request.uri.toString();
    if (!_measure.shouldTrackHttpEvent(rawUrl)) {
      handler.next(err);
      _requestsStartTime.remove(request);
      return;
    }

    try {
      final int startTime =
          _requestsStartTime[request] ?? Measure.instance.getCurrentTime();
      trackStarMeasureHttpEvent(
        measure: _measure,
        url: redactMeasureHttpUrl(rawUrl),
        method: _method(request),
        startTime: startTime,
        endTime: Measure.instance.getCurrentTime(),
        failureReason: _failureReason(err),
        failureDescription: err.message ?? err.error?.toString(),
      );
    } on Object catch (e, stacktrace) {
      _logInternalError(e, stacktrace);
    } finally {
      handler.next(err);
      _requestsStartTime.remove(request);
    }
  }

  String _method(RequestOptions request) => request.method.toLowerCase();

  String _failureReason(DioException err) {
    if (err.type != DioExceptionType.unknown) {
      return err.type.toString();
    }
    return err.runtimeType.toString();
  }

  void _logInternalError(Object e, StackTrace stacktrace) {
    developer.log(
      'Failed to track HTTP event',
      error: e,
      stackTrace: stacktrace,
      name: 'star-measure-dio',
    );
  }
}
