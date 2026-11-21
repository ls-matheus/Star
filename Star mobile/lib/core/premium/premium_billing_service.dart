import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/api/api_exception.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_dart/export.dart';

Future<String> createPremiumCustomerPortalSession(WidgetRef ref) async {
  final StarClient client = ref.read(starClientProvider);
  final UrlResponse response = await client.premium.createCustomerPortal();
  final String url = response.url;
  if (url.isEmpty) {
    throw const ApiException();
  }
  return url;
}
