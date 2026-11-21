import 'package:star_dart/export.dart';

const Map<String, Object> _featureDefaultsForOlderServers = <String, Object>{
  'phone_verification_enabled': false,
};

const String _kProxyAttachmentsFeature = 'proxy_attachments_through_api';

final Expando<bool> _proxiedAttachments = Expando<bool>(
  _kProxyAttachmentsFeature,
);

bool proxiesAttachmentsThroughApi(WellKnownStarResponse response) =>
    _proxiedAttachments[response] ?? false;

Map<String, dynamic> wellKnownStarToJson(WellKnownStarResponse response) {
  final Map<String, dynamic> json = response.toJson();
  if (!proxiesAttachmentsThroughApi(response)) {
    return json;
  }
  return <String, dynamic>{
    ...json,
    'features': <String, dynamic>{
      ...response.features.toJson(),
      _kProxyAttachmentsFeature: true,
    },
  };
}

WellKnownStarResponse parseWellKnownStar(Map<String, dynamic> json) {
  final Object? features = json['features'];
  if (features is! Map) {
    return WellKnownStarResponse.fromJson(json);
  }
  final Map<String, dynamic> filledFeatures = Map<String, dynamic>.from(
    features,
  );
  _featureDefaultsForOlderServers.forEach((String key, Object value) {
    filledFeatures.putIfAbsent(key, () => value);
  });
  final WellKnownStarResponse response = WellKnownStarResponse.fromJson(
    <String, dynamic>{...json, 'features': filledFeatures},
  );
  if (features[_kProxyAttachmentsFeature] == true) {
    _proxiedAttachments[response] = true;
  }
  return response;
}
