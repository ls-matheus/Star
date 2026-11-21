const double kStarBottomSheetDismissHeightFraction = 0.5;
const double kStarBottomSheetDismissVelocity = 800;
const double kStarBottomSheetHalfSize = 0.5;
const double kStarBottomSheetFullSize = 0.95;

const double kStarBottomSheetDragMinSize = 0.05;

const double _kSnapEpsilon = 0.001;
const double _kSnapProjectionSeconds = 0.2;

double starBottomSheetSizeAfterDrag({
  required double currentSize,
  required double deltaDy,
  required double availablePixels,
  required double minChildSize,
  required double maxChildSize,
}) {
  if (currentSize <= 0 || availablePixels <= 0) {
    return currentSize;
  }
  final double deltaSize = deltaDy / availablePixels;
  return (currentSize - deltaSize).clamp(minChildSize, maxChildSize);
}

bool starBottomSheetShouldDismissAfterDrag({
  required double dragDistance,
  required double velocity,
  required double sheetHeight,
}) =>
    dragDistance > sheetHeight * kStarBottomSheetDismissHeightFraction ||
    velocity > kStarBottomSheetDismissVelocity;

double? starBottomSheetSnapTarget({
  required double size,
  required double halfSize,
  required double fullSize,
  double velocity = 0,
  double availablePixels = 1,
}) {
  if (fullSize - halfSize <= _kSnapEpsilon) {
    final bool closes =
        velocity > kStarBottomSheetDismissVelocity ||
        size < fullSize * kStarBottomSheetDismissHeightFraction;
    return closes ? null : fullSize;
  }

  final bool atOrBelowHalf = size <= halfSize + _kSnapEpsilon;
  if (atOrBelowHalf &&
      (velocity > kStarBottomSheetDismissVelocity ||
          size < halfSize * kStarBottomSheetDismissHeightFraction)) {
    return null;
  }
  if (size < halfSize) {
    return halfSize;
  }

  double projected = size;
  if (availablePixels > 0 && velocity.abs() > 0) {
    projected = size - (velocity * _kSnapProjectionSeconds) / availablePixels;
  }
  projected = projected.clamp(halfSize, fullSize);

  final double midpoint = (halfSize + fullSize) / 2;
  return projected < midpoint ? halfSize : fullSize;
}
