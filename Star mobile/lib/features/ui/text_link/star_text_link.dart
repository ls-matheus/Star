import 'dart:async';

import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/features/ui/tappable/star_tappable.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/external_links/external_link_handler.dart';

class StarTextLink extends StatelessWidget {
  const StarTextLink({
    required this.text,
    this.url,
    this.onTap,
    this.style,
    this.color,
    this.selectable = false,
    this.underline = false,
    super.key,
  });

  final String text;
  final String? url;
  final VoidCallback? onTap;
  final TextStyle? style;
  final Color? color;
  final bool selectable;
  final bool underline;

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    if (url != null) {
      unawaited(handleExternalLinkTap(context, url!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final baseStyle = (style ?? DefaultTextStyle.of(context).style).copyWith(
      color: color ?? colors.textLink,
    );

    return StarTappable(
      onTap: () => _handleTap(context),
      link: true,
      linkUrl: url != null ? Uri.tryParse(url!) : null,
      button: false,
      semanticLabel: text,
      excludeChildSemantics: !selectable,
      builder: (context, states) {
        final isHovered = states.contains(WidgetState.hovered);
        final linkStyle = baseStyle.copyWith(
          decoration: underline || isHovered
              ? TextDecoration.underline
              : TextDecoration.none,
          decorationColor: baseStyle.color,
        );

        if (selectable) {
          return SelectableText(text, style: linkStyle);
        }

        return Text(text, style: linkStyle);
      },
    );
  }
}

@StarWidgetPreview(name: 'Default', group: 'StarTextLink')
Widget starTextLinkPreview() {
  return StarTextLink(text: 'Open documentation', onTap: () {});
}
