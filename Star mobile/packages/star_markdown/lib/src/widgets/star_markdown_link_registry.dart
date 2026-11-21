import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class StarMarkdownLinkRecognizer extends TapGestureRecognizer {
  StarMarkdownLinkRecognizer({required this.href});

  final String href;
}

class StarMarkdownLinkRegistry extends InheritedWidget {
  const StarMarkdownLinkRegistry({
    required this.obtainRecognizer,
    required super.child,
    super.key,
  });

  final StarMarkdownLinkRecognizer Function(String href, VoidCallback onTap)
  obtainRecognizer;

  static StarMarkdownLinkRegistry? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<StarMarkdownLinkRegistry>();
  }

  @override
  bool updateShouldNotify(covariant StarMarkdownLinkRegistry oldWidget) {
    return false;
  }
}

String? starMarkdownLinkHrefAt(RenderBox root, Offset globalPosition) {
  final BoxHitTestResult result = BoxHitTestResult();
  root.hitTest(result, position: root.globalToLocal(globalPosition));
  for (final HitTestEntry<HitTestTarget> entry in result.path) {
    final HitTestTarget target = entry.target;
    if (target is TextSpan) {
      final GestureRecognizer? recognizer = target.recognizer;
      if (recognizer is StarMarkdownLinkRecognizer) {
        return recognizer.href;
      }
    }
  }
  return null;
}
