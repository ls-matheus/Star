import 'package:flutter/widget_previews.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/l10n/star_localizations_delegates.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

final class StarWidgetPreview extends Preview {
  const StarWidgetPreview({
    super.name,
    super.group,
    super.size,
    super.textScaleFactor,
    super.brightness,
    super.localizations,
    super.wrapper = _defaultWrapper,
  });

  static Widget _defaultWrapper(Widget child) {
    return _PreviewAppWrapper(child: child);
  }
}

class _PreviewAppWrapper extends StatelessWidget {
  const _PreviewAppWrapper({required this.child});

  final Widget child;

  static final StarLayoutTheme _layoutTheme = StarLayoutTheme.scaled();
  static final StarColorTheme _colorTheme = buildDarkColorTheme();
  static final StarTextTheme _textTheme = StarTextTheme.fromColors(
    _colorTheme,
  );
  static final ThemeData _theme = buildStarTheme(
    colorTheme: _colorTheme,
    textTheme: _textTheme,
    layoutTheme: _layoutTheme,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Star',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: starLocalizationsDelegates,
      supportedLocales: StarLocalizations.supportedLocales,
      theme: _theme,
      home: Scaffold(body: Center(child: child)),
    );
  }
}
