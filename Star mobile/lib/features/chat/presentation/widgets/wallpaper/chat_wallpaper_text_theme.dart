import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_color_override_scope.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/providers/theme_preference_provider.dart';
import 'package:star_app/features/chat/providers/chat_wallpaper_provider.dart';
import 'package:star_app/features/chat/utils/wallpaper/chat_wallpaper_text_overlay.dart';
import 'package:star_app/features/chat/wallpaper/chat_wallpaper.dart';
import 'package:star_app/material_ui.dart';

class ChatSurfaceTheme extends StatelessWidget {
  const ChatSurfaceTheme({required this.builder, super.key});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    if (!StarColorOverrideScope.isActiveOf(context)) {
      return builder(context);
    }
    return StarColorOverrideScope(
      colors: null,
      textStyles: null,
      child: Builder(builder: builder),
    );
  }
}

class ChatWallpaperTextTheme extends ConsumerWidget {
  const ChatWallpaperTextTheme({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ChatWallpaperState resolved = ref.watch(
      chatWallpaperProvider.select(
        (ChatWallpaperSnapshot snapshot) => snapshot.resolved,
      ),
    );
    final Brightness themeBrightness = Theme.of(context).brightness;
    final Brightness? tone = resolveChatWallpaperTone(resolved);
    if (tone == null || tone == themeBrightness) {
      return child;
    }
    final StarColorTheme source = ref.watch(
      themePreferenceProvider.select(
        (ThemePreferenceState prefs) => tone == Brightness.dark
            ? prefs.darkColorTheme
            : prefs.lightColorTheme,
      ),
    );
    final StarColorTheme currentColors = Theme.of(
      context,
    ).extension<StarColorTheme>()!;
    final StarColorTheme mixed = overlayChatWallpaperColors(
      current: currentColors,
      source: source,
    );
    final StarTextTheme currentText = Theme.of(
      context,
    ).extension<StarTextTheme>()!;
    return StarColorOverrideScope(
      colors: mixed,
      textStyles: overlayChatWallpaperTextStyles(
        current: currentText,
        colors: mixed,
      ),
      child: child,
    );
  }
}
