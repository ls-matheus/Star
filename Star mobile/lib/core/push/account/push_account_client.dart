import 'package:dio/dio.dart';
import 'package:star_app/core/api/star_api_features.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/api/session_authorization_header.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

Dio createPushAccountDio(
  Ref ref, {
  required String token,
  required String apiBaseUrl,
}) {
  return Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      contentType: 'application/json',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: <String, dynamic>{
        'Authorization': formatSessionAuthorizationHeader(token),
        'User-Agent': ref.read(starClientPropertiesProvider).userAgent,
        'X-Star-Client-Properties': ref.read(
          starClientPropertiesHeaderProvider,
        ),
        starApiFeaturesHeaderName: buildStarApiFeaturesHeaderValue(),
      },
    ),
  );
}
