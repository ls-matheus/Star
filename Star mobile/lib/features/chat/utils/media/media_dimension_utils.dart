import 'dart:math' as math;
import 'dart:ui';

import 'package:star_app/features/settings/providers/preferences/chat_preferences_provider.dart';

class StarMediaDimensions {
  const StarMediaDimensions({
    required this.maxWidth,
    required this.maxHeight,
  });

  final double maxWidth;
  final double maxHeight;
}

const StarMediaDimensions compactMediaDimensions = StarMediaDimensions(
  maxWidth: 400,
  maxHeight: 300,
);
const StarMediaDimensions comfortableMediaDimensions = StarMediaDimensions(
  maxWidth: 550,
  maxHeight: 400,
);

StarMediaDimensions mediaDimensionsForSize(MediaDimensionSize size) {
  return switch (size) {
    MediaDimensionSize.small => compactMediaDimensions,
    MediaDimensionSize.large => comfortableMediaDimensions,
  };
}

StarMediaDimensions mediaDimensionsWithinWidth(
  StarMediaDimensions dimensions,
  double availableWidth,
) {
  if (!availableWidth.isFinite ||
      availableWidth <= 0 ||
      availableWidth >= dimensions.maxWidth) {
    return dimensions;
  }
  return StarMediaDimensions(
    maxWidth: availableWidth,
    maxHeight: dimensions.maxHeight,
  );
}

const double kAnimatedImageMaxDevicePixelRatio = 2;

double animatedImagePixelRatio(double devicePixelRatio) {
  if (!devicePixelRatio.isFinite || devicePixelRatio <= 0) {
    return 1;
  }
  return math.min(devicePixelRatio, kAnimatedImageMaxDevicePixelRatio);
}

Size? constrainMediaSize({
  required StarMediaDimensions dimensions,
  required int? width,
  required int? height,
}) {
  if (width == null || height == null || width <= 0 || height <= 0) {
    return null;
  }

  final sourceWidth = width.toDouble();
  final sourceHeight = height.toDouble();
  final scale = math.min(
    1,
    math.min(
      dimensions.maxWidth / sourceWidth,
      dimensions.maxHeight / sourceHeight,
    ),
  );

  return Size(sourceWidth * scale, sourceHeight * scale);
}

({int? width, int? height}) coverDecodeCacheSize({
  required double cellWidth,
  required double cellHeight,
  required double devicePixelRatio,
  int? sourceWidth,
  int? sourceHeight,
}) => _decodeCacheSize(
  cellWidth: cellWidth,
  cellHeight: cellHeight,
  devicePixelRatio: devicePixelRatio,
  sourceWidth: sourceWidth,
  sourceHeight: sourceHeight,
  fitsInside: false,
);

({int? width, int? height}) containDecodeCacheSize({
  required double cellWidth,
  required double cellHeight,
  required double devicePixelRatio,
  int? sourceWidth,
  int? sourceHeight,
}) => _decodeCacheSize(
  cellWidth: cellWidth,
  cellHeight: cellHeight,
  devicePixelRatio: devicePixelRatio,
  sourceWidth: sourceWidth,
  sourceHeight: sourceHeight,
  fitsInside: true,
);

({int? width, int? height}) _decodeCacheSize({
  required double cellWidth,
  required double cellHeight,
  required double devicePixelRatio,
  required int? sourceWidth,
  required int? sourceHeight,
  required bool fitsInside,
}) {
  if (!cellWidth.isFinite ||
      !cellHeight.isFinite ||
      cellWidth <= 0 ||
      cellHeight <= 0) {
    return (width: null, height: null);
  }
  final bool capHeight;
  if (sourceWidth != null &&
      sourceHeight != null &&
      sourceWidth > 0 &&
      sourceHeight > 0) {
    final bool sourceWiderThanCell =
        sourceWidth / sourceHeight > cellWidth / cellHeight;
    capHeight = fitsInside ? !sourceWiderThanCell : sourceWiderThanCell;
  } else {
    capHeight = cellHeight >= cellWidth;
  }
  if (capHeight) {
    return (width: null, height: (cellHeight * devicePixelRatio).round());
  }
  return (width: (cellWidth * devicePixelRatio).round(), height: null);
}
