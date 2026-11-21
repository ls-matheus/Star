import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/spinner/star_loading_spinner.dart';
import 'package:star_app/features/ui/tappable/star_tappable.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

const double kChatFloatingButtonExtent = 40;
const double kChatFloatingButtonRadius = 10;
const double kChatFloatingButtonGap = 8;

class ChatFloatingButton extends StatelessWidget {
  const ChatFloatingButton({
    required this.icon,
    required this.iconSize,
    required this.semanticLabel,
    required this.onTap,
    this.isLoading = false,
    super.key,
  });

  final IconData icon;
  final double iconSize;
  final String semanticLabel;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return StarTappable(
      onTap: isLoading ? null : onTap,
      enabled: onTap != null && !isLoading,
      semanticLabel: semanticLabel,
      builder: (BuildContext context, Set<WidgetState> states) =>
          SizedBox.square(
            dimension: kChatFloatingButtonExtent,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: colors.backgroundTextarea,
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(
                    kChatFloatingButtonRadius,
                  ),
                ),
              ),
              child: Center(
                child: isLoading
                    ? StarLoadingSpinner(
                        size: StarLoadingSpinnerSize.small,
                        color: colors.textTertiary,
                      )
                    : PhosphorIcon(
                        icon,
                        size: iconSize,
                        color: colors.textTertiary,
                      ),
              ),
            ),
          ),
    );
  }
}

class ChatJumpToBottomButton extends StatelessWidget {
  const ChatJumpToBottomButton({
    required this.onTap,
    this.isLoading = false,
    super.key,
  });

  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ChatFloatingButton(
      icon: PhosphorIconsBold.arrowDown,
      iconSize: 21,
      semanticLabel: StarLocalizations.of(context).chatJumpToBottom,
      isLoading: isLoading,
      onTap: onTap,
    );
  }
}

class ChatCloseButton extends StatelessWidget {
  const ChatCloseButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChatFloatingButton(
      icon: PhosphorIconsRegular.x,
      iconSize: 26,
      semanticLabel: StarLocalizations.of(context).uiClose,
      onTap: onTap,
    );
  }
}
