import 'package:flutter/foundation.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/widgets/star_render_error_placeholder.dart';

void configureStarErrorUi() {
  if (kDebugMode) {
    return;
  }
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const StarRenderErrorPlaceholder();
  };
}
