import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoTheme, CupertinoThemeData;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/age/declared_age_range_lock.dart';
import 'package:star_app/core/assistant/assistant_binding.dart';
import 'package:star_app/core/desktop/window/desktop_main_window.dart';
import 'package:star_app/core/instance/account_identity_sync.dart';
import 'package:star_app/core/platform/star_platform.dart';
import 'package:star_app/core/providers/app/app_ui_lifecycle_provider.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/quick_actions/home_quick_actions_binding.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/star_theme_mode.dart';
import 'package:star_app/core/theme/providers/theme_preference_provider.dart';
import 'package:star_app/core/zoom/star_app_zoom.dart';
import 'package:star_app/features/accessibility/domain/resolve_reduced_motion.dart';
import 'package:star_app/features/accessibility/domain/text_scale.dart';
import 'package:star_app/features/accessibility/presentation/reduced_motion_scope.dart';
import 'package:star_app/features/accessibility/providers/effective_motion_preferences_provider.dart';
import 'package:star_app/features/accessibility/providers/screen_reader_active_provider.dart';
import 'package:star_app/features/app_lock/presentation/app_lock_gate.dart';
import 'package:star_app/features/recovery_kit/presentation/recovery_kit_gate.dart';
import 'package:star_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:star_app/features/shell/hosted_ui/iphone_duo_app_background.dart';
import 'package:star_app/features/shell/presentation/gateway_reconnect_banner.dart';
import 'package:star_app/features/shell/presentation/instance_compatibility_gate.dart';
import 'package:star_app/features/shell/presentation/native_titlebar.dart';
import 'package:star_app/features/ui/input/star_clipboard_scope.dart';
import 'package:star_app/features/ui/toast/star_toast_overlay.dart';
import 'package:star_app/features/voice/presentation/widgets/incoming_voice_call_layer.dart';
import 'package:star_app/features/voice/presentation/widgets/pip/voice_pip_layer.dart';
import 'package:star_app/features/voice/presentation/widgets/pip/voice_system_pip_view.dart';
import 'package:star_app/features/voice/presentation/widgets/voice_call_accessibility_layer.dart';
import 'package:star_app/l10n/app_locale_provider.dart';
import 'package:star_app/l10n/star_localizations_delegates.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';
import 'package:star_app/shared/widgets/beta_banner.dart';
import 'package:star_app/shared/widgets/input_modality_listener.dart';
import 'package:foldable/foldable.dart';
import 'package:window_manager/window_manager.dart';

class StarApp extends ConsumerStatefulWidget {
  const StarApp({super.key});

  @override
  ConsumerState<StarApp> createState() => _StarAppState();
}

class _StarAppState extends ConsumerState<StarApp> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<double>(
      themePreferenceProvider.select(
        (ThemePreferenceState state) => state.scaleFactor,
      ),
      (double? previous, double next) => StarAppZoom.apply(next),
      fireImmediately: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..watch(homeQuickActionsBindingProvider)
      ..watch(assistantBindingProvider);
    final router = ref.watch(starRouterProvider);
    final ({
      StarThemeMode mode,
      StarColorTheme active,
      StarColorTheme light,
      StarColorTheme dark,
    })
    themePref = ref.watch(
      themePreferenceProvider.select(
        (ThemePreferenceState state) => (
          mode: state.mode,
          active: state.colorTheme,
          light: state.lightColorTheme,
          dark: state.darkColorTheme,
        ),
      ),
    );
    final Locale appLocale = ref.watch(effectiveAppLocaleProvider);
    final ({bool sync, bool override}) reducedMotionPrefs = ref.watch(
      appearancePreferencesProvider.select(
        (AppearancePreferencesState s) => (
          sync: s.syncReducedMotionWithSystem,
          override: s.reducedMotionOverride,
        ),
      ),
    );

    final ThemeMode themeMode;
    final ThemeData theme;
    final ThemeData? darkThemeData;
    switch (themePref.mode) {
      case StarThemeMode.system:
        themeMode = ThemeMode.system;
        theme = cachedStarTheme(
          colorTheme: themePref.light,
          brightness: Brightness.light,
        );
        darkThemeData = cachedStarTheme(colorTheme: themePref.dark);
      case StarThemeMode.light:
        themeMode = ThemeMode.light;
        theme = cachedStarTheme(
          colorTheme: themePref.active,
          brightness: Brightness.light,
        );
        darkThemeData = null;
      case StarThemeMode.dark:
      case StarThemeMode.darkLegacy:
      case StarThemeMode.coal:
        themeMode = ThemeMode.dark;
        theme = cachedStarTheme(colorTheme: themePref.active);
        darkThemeData = theme;
    }

    final String productName = ref.watch(
      instanceRuntimeConfigProvider.select((config) => config.productName),
    );
    if (isStarDesktopOs) {
      setDesktopMainWindowTitle(productName);
    }

    return StarAppZoomScope(
      child: FoldableProvider(
        child: MaterialApp.router(
          title: productName,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: starLocalizationsDelegates,
          supportedLocales: StarLocalizations.supportedLocales,
          locale: appLocale,
          theme: theme,
          darkTheme: darkThemeData,
          themeMode: themeMode,
          themeAnimationDuration: Duration.zero,
          routerConfig: router,
          builder: (context, child) {
            final Widget layered = ScreenReaderActiveSync(
              child: InputModalityListener(
                child: AppUiLifecycleObserver(
                  child: AccountIdentitySync(
                    child: RecoveryKitGate(
                      child: DeclaredAgeRangeLock(
                        child: IncomingVoiceCallLayer(
                          child: VoiceCallAccessibilityLayer(
                            child: VoicePipLayer(child: child!),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            Widget overlayStack(Widget child) {
              return StarToastOverlay(
                child: InstanceCompatibilityGate(
                  child: GatewayReconnectBannerOverlay(child: child),
                ),
              );
            }

            final Widget content;
            if (!isStarDesktopOs) {
              content = BetaBanner(child: overlayStack(layered));
            } else {
              content = overlayStack(
                DragToResizeArea(
                  child: Column(
                    children: [
                      const NativeTitlebar(),
                      Expanded(child: layered),
                    ],
                  ),
                ),
              );
            }

            final bool platformReducedMotion = platformReducedMotionOf(
              ref,
              context,
            );
            final bool disableAnimations = resolveReducedMotion(
              syncReducedMotionWithSystem: reducedMotionPrefs.sync,
              reducedMotionOverride: reducedMotionPrefs.override,
              platformReducedMotion: platformReducedMotion,
            );
            final Widget scaled = ReducedMotionScope(
              enabled: disableAnimations,
              child: StarAppTextScale(
                child: DesktopPointerUiScope(
                  child: isStarNativeAndroid
                      ? VoiceSystemPipHost(child: AppLockGate(child: content))
                      : AppLockGate(child: content),
                ),
              ),
            );
            final ThemeData materialTheme = Theme.of(context);
            final CupertinoThemeData cupertinoTheme = CupertinoTheme.of(context)
                .copyWith(
                  brightness: materialTheme.brightness,
                  scaffoldBackgroundColor:
                      materialTheme.scaffoldBackgroundColor,
                );
            final Widget appBody = Material(
              type: MaterialType.transparency,
              child: CupertinoTheme(
                data: cupertinoTheme,
                child: AdaptiveToolbarHost(
                  child: IphoneDuoAppBackground(
                    child: AnnotatedRegion<SystemUiOverlayStyle>(
                      value:
                          materialTheme.appBarTheme.systemOverlayStyle ??
                          starSystemUiOverlayStyle(
                            brightness: materialTheme.brightness,
                            navigationBarColor:
                                materialTheme.scaffoldBackgroundColor,
                          ),
                      child: NativePasteShortcuts(child: scaled),
                    ),
                  ),
                ),
              ),
            );
            // Paint the current theme behind transparent Android system bars,
            // including routes whose content uses SafeArea for gesture space.
            return isStarNativeAndroid
                ? ColoredBox(
                    color: materialTheme.scaffoldBackgroundColor,
                    child: appBody,
                  )
                : appBody;
          },
        ),
      ),
    );
  }
}
