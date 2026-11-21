import 'package:star_app/core/instance/instance_endpoints.dart';

export 'package:star_app/core/instance/instance_endpoints.dart'
    show InstanceEndpoints;

String get starMediaCdn => InstanceEndpoints.media;

String get starStaticCdn => InstanceEndpoints.staticCdn;
