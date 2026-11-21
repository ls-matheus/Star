import 'dart:ui';

import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/shell/foldable/crease_overlay_layout.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/shell/utils/shell_popup_presentation.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/desktop_surface/star_desktop_surface.dart';
import 'package:star_app/features/ui/overlay/star_overlay_back_handler.dart';
import 'package:star_app/features/ui/tappable/star_gesture_detector.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';

typedef StarModalBuilder =
    Widget Function(BuildContext context, VoidCallback close);

typedef StarModalActionsBuilder<T> =
    List<Widget> Function(void Function([T? result]) pop);

class StarModal {
  StarModal._();

  static bool _isActionSpacer(Widget action) =>
      action is SizedBox && action.child == null;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required StarModalBuilder builder,
    List<Widget>? actions,
    StarModalActionsBuilder<T>? actionsBuilder,
    String? description,
    Widget? trailing,
    VoidCallback? onBack,
    bool centered = false,
    bool? useRootNavigator,
  }) {
    return showDialog<T>(
      context: context,
      useRootNavigator:
          useRootNavigator ?? resolveShellPopupUseRootNavigator(context),
      barrierColor: Colors.transparent,
      builder: (dialogContext) {
        void close() => Navigator.of(dialogContext).pop();
        void pop([T? result]) => Navigator.of(dialogContext).pop(result);
        final List<Widget> footerActions =
            actions ?? actionsBuilder?.call(pop) ?? const <Widget>[];

        final colors = dialogContext.colors;
        final textStyles = dialogContext.textStyles;
        final layout = dialogContext.layout;
        final dialogTheme = DialogTheme.of(dialogContext);
        final mediaQuery = MediaQuery.of(dialogContext);
        final double keyboardInset = mediaQuery.viewInsets.bottom;
        final isMobile = isMobileLayout(dialogContext);
        final useMobileFullscreen = isMobile && !centered;
        final bool desktop =
            !useMobileFullscreen && usesDesktopPointerUi(dialogContext);

        final themeShape = dialogTheme.shape as RoundedRectangleBorder?;
        final headerSubtitle = description == null
            ? null
            : Text(
                description,
                style: textStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              );
        final StarLocalizations l10n = StarLocalizations.of(dialogContext);
        final Widget closeButton = desktop
            ? StarDesktopModalCloseButton(onTap: close)
            : Opacity(
                opacity: 0.7,
                child: StarButton.ghost(
                  onPressed: close,
                  icon: PhosphorIconsBold.x,
                  isSquare: true,
                  semanticLabel: l10n.uiClose,
                ),
              );

        final Widget header = StarBottomSheetHeader(
          title: title,
          subtitle: headerSubtitle,
          onBack: onBack,
          trailing: trailing ?? closeButton,
        );

        Widget buildModalContent({required bool mobileFullscreen}) {
          final double dialogMaxHeight =
              mediaQuery.size.height -
              mediaQuery.viewPadding.top -
              layout.s2 -
              keyboardInset;
          final body = Padding(
            padding: EdgeInsets.fromLTRB(layout.s4, 0, layout.s4, layout.s4),
            child: SingleChildScrollView(child: builder(dialogContext, close)),
          );

          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: desktop ? 440 : 400,
              maxHeight: dialogMaxHeight,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: layout.s4, bottom: layout.s4),
                  child: desktop
                      ? StarDesktopSurfaceScope(
                          surface: StarDesktopSurface.modal,
                          child: header,
                        )
                      : header,
                ),
                if (mobileFullscreen)
                  Flexible(child: body)
                else
                  LimitedBox(
                    maxHeight:
                        (dialogMaxHeight - layout.headerHeight - layout.s16)
                            .clamp(0.0, dialogMaxHeight),
                    child: body,
                  ),
                if (footerActions.isNotEmpty && desktop)
                  StarBottomSheetFooter(
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final Widget action in footerActions.reversed)
                          if (!_isActionSpacer(action)) action,
                      ],
                    ),
                  )
                else if (footerActions.isNotEmpty)
                  StarBottomSheetFooter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: footerActions,
                    ),
                  ),
              ],
            ),
          );
        }

        final Widget centeredDialog = Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: desktop ? layout.radiusLg : layout.radiusXxl,
            side: themeShape?.side ?? BorderSide.none,
          ),
          child: buildModalContent(mobileFullscreen: false),
        );

        return wrapStarOverlayBackHandler(
          canDismiss: true,
          onBack: onBack,
          onDismiss: close,
          child: Stack(
            children: [
              Positioned.fill(
                child: StarGestureDetector(
                  onTap: close,
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),

              AnimatedPadding(
                duration: dialogContext.motion.normal,
                curve: dialogContext.motion.curve,
                padding: EdgeInsets.only(bottom: keyboardInset),
                child: MediaQuery.removeViewInsets(
                  context: dialogContext,
                  removeBottom: true,
                  child: useMobileFullscreen
                      ? SafeArea(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: layout.s2,
                              ),
                              child: Material(
                                color: dialogTheme.backgroundColor,
                                surfaceTintColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: layout.radiusXxl.topLeft,
                                  ),
                                  side: themeShape?.side ?? BorderSide.none,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: buildModalContent(
                                  mobileFullscreen: true,
                                ),
                              ),
                            ),
                          ),
                        )
                      : keyboardInset > 0
                      ? Align(
                          alignment: Alignment.bottomCenter,
                          child: centeredDialog,
                        )
                      : CreaseAwareAlign(child: centeredDialog),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class StarConfirmModal {
  StarConfirmModal._();

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String description,
    required VoidCallback onConfirm,
    String? confirmLabel,
    Widget? body,
    bool isDanger = false,
    bool? useRootNavigator,
  }) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final String resolvedConfirmLabel = confirmLabel ?? l10n.uiConfirm;
    return StarModal.show<bool>(
      context,
      useRootNavigator: useRootNavigator,
      title: title,
      centered: true,
      builder: (dialogContext, close) {
        final textStyles = dialogContext.textStyles;
        final layout = dialogContext.layout;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              description,
              style: textStyles.bodySmall.copyWith(height: 1.4),
            ),
            if (body != null) ...[SizedBox(height: layout.s4), body],
          ],
        );
      },
      actionsBuilder: (pop) => [
        if (isDanger)
          StarButton.dangerPrimary(
            onPressed: () {
              onConfirm();
              pop(true);
            },
            label: resolvedConfirmLabel,
          )
        else
          StarButton.primary(
            onPressed: () {
              onConfirm();
              pop(true);
            },
            label: resolvedConfirmLabel,
          ),
        const SizedBox(height: 8),
        StarButton.secondary(onPressed: () => pop(false), label: l10n.cancel),
      ],
    );
  }
}
