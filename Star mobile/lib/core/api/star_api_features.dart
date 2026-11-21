const String starApiFeaturesHeaderName = 'X-Star-Features';

const List<String> starApiClientFeatures = <String>[
  'view_channel_members_permission',
  'channel_threads',
];

String buildStarApiFeaturesHeaderValue() =>
    starApiClientFeatures.join(', ');
