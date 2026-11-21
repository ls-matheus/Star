import 'package:flutter/services.dart';
import 'package:star_app/core/platform/star_platform.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/desktop_surface/star_desktop_surface.dart';
import 'package:star_app/features/ui/input/star_clipboard_scope.dart';
import 'package:star_app/features/ui/tappable/star_gesture_detector.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';

const double kPickerSearchInputHeight = 40;

class PickerSearchInput extends StatefulWidget {
  const PickerSearchInput({
    required this.hintText,
    this.controller,
    this.rightCustomElement,
    this.horizontalPadding = 12,
    this.rightPadding,
    this.topPadding = 12,
    this.bottomPadding = 12,
    this.maxLength = 100,
    this.onChanged,
    this.onSubmitted,
    this.onCleared,
    this.focusNode,
    this.onActivated,
    this.autofocus = false,
    this.enabled = true,
    super.key,
  }) : desktopSettingsStyle = false;

  const PickerSearchInput.inline({
    required this.hintText,
    this.controller,
    this.rightCustomElement,
    this.maxLength = 100,
    this.onChanged,
    this.onSubmitted,
    this.onCleared,
    this.focusNode,
    this.onActivated,
    this.autofocus = false,
    this.enabled = true,
    this.desktopSettingsStyle = false,
    super.key,
  }) : horizontalPadding = 0,
       rightPadding = null,
       topPadding = 0,
       bottomPadding = 0;

  final TextEditingController? controller;
  final String hintText;
  final Widget? rightCustomElement;
  final double horizontalPadding;
  final double? rightPadding;
  final double topPadding;
  final double bottomPadding;
  final int maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onCleared;
  final FocusNode? focusNode;
  final VoidCallback? onActivated;
  final bool autofocus;
  final bool enabled;
  final bool desktopSettingsStyle;

  @override
  State<PickerSearchInput> createState() => _PickerSearchInputState();
}

class _PickerSearchInputState extends State<PickerSearchInput> {
  FocusNode? _ownedFocusNode;
  late FocusNode _focusNode;
  TextEditingController? _ownedController;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? (_ownedFocusNode = FocusNode());
    _focusNode.addListener(_handleFocusChange);
    _controller =
        widget.controller ?? (_ownedController = TextEditingController());
  }

  @override
  void didUpdateWidget(PickerSearchInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _ownedController?.dispose();
      _ownedController = null;
      _controller =
          widget.controller ?? (_ownedController = TextEditingController());
    }
    if (oldWidget.focusNode == widget.focusNode) {
      return;
    }
    _focusNode.removeListener(_handleFocusChange);
    _ownedFocusNode?.dispose();
    _ownedFocusNode = null;
    _focusNode = widget.focusNode ?? (_ownedFocusNode = FocusNode());
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _ownedFocusNode?.dispose();
    _ownedController?.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      widget.onActivated?.call();
    });
  }

  void _clear() {
    _controller.clear();
    _focusNode.unfocus();
    widget.onChanged?.call('');
    widget.onCleared?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final searchInputFillColor = _resolveSearchInputFillColor(context, colors);
    final bool autofocus =
        widget.autofocus && !StarBottomSheet.isInSheet(context);
    final BorderRadius radius = BorderRadius.circular(8);
    final bool desktopSettings =
        widget.desktopSettingsStyle && usesDesktopPointerUi(context);
    final OutlineInputBorder idleBorder = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: colors.backgroundModifierAccent),
    );

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: widget.horizontalPadding,
        end: widget.rightPadding ?? widget.horizontalPadding,
        top: widget.topPadding,
        bottom: widget.bottomPadding,
      ),
      child: Row(
        children: [
          Expanded(
            child: StarClipboardScope(
              controller: _controller,
              focusNode: _focusNode,
              builder:
                  (
                    BuildContext context,
                    StarClipboardScopeState clipboardScope,
                    FocusNode focusNode,
                  ) {
                    return ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _controller,
                      builder: (context, value, _) {
                        if (desktopSettings) {
                          return _buildDesktopSettingsField(
                            context,
                            focusNode: focusNode,
                            autofocus: autofocus,
                            contextMenuBuilder: clipboardScope.buildContextMenu,
                            text: value.text,
                          );
                        }
                        return TextField(
                          controller: _controller,
                          focusNode: focusNode,
                          autofocus: autofocus,
                          enabled: widget.enabled,
                          onChanged: widget.onChanged,
                          onSubmitted: widget.onSubmitted,
                          maxLength: widget.maxLength,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          textInputAction: TextInputAction.search,
                          autocorrect: false,
                          cursorColor: colors.textPrimary,
                          style: context.textStyles.inputText.copyWith(
                            color: colors.textPrimary,
                            height: 1.25,
                          ),
                          contextMenuBuilder: clipboardScope.buildContextMenu,
                          decoration: InputDecoration(
                            counterText: '',
                            isDense: true,
                            hintText: widget.hintText,
                            hintStyle: context.textStyles.inputHint.copyWith(
                              color: colors.textTertiary,
                              height: 1.25,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 14,
                                end: 7,
                              ),
                              child: Icon(
                                PhosphorIconsBold.magnifyingGlass,
                                size: 16,
                                color: colors.textTertiary,
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 37,
                              minHeight: kPickerSearchInputHeight,
                            ),
                            suffixIcon: _renderRightElement(colors, value.text),
                            suffixIconConstraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: kPickerSearchInputHeight,
                              maxHeight: kPickerSearchInputHeight,
                            ),
                            filled: true,
                            fillColor: searchInputFillColor,
                            contentPadding:
                                const EdgeInsetsDirectional.fromSTEB(
                                  0,
                                  10,
                                  14,
                                  10,
                                ),
                            border: idleBorder,
                            enabledBorder: idleBorder,
                            disabledBorder: idleBorder,
                            focusedBorder: isStarMobileOs
                                ? idleBorder
                                : OutlineInputBorder(
                                    borderRadius: radius,
                                    borderSide: BorderSide(
                                      color: colors.brandPrimary,
                                    ),
                                  ),
                          ),
                        );
                      },
                    );
                  },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSettingsField(
    BuildContext context, {
    required FocusNode focusNode,
    required bool autofocus,
    required EditableTextContextMenuBuilder contextMenuBuilder,
    required String text,
  }) {
    final colors = context.colors;
    final BorderRadius radius = context.layout.radiusLg;
    final OutlineInputBorder idleBorder = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: colors.backgroundModifierAccent),
    );
    final TextStyle textStyle = context.textStyles.inputText.copyWith(
      fontSize: 13,
      height: 18 / 13,
      color: colors.textPrimary,
    );
    final bool hasText = text.isNotEmpty;
    return TextField(
      controller: _controller,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      maxLength: widget.maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      cursorColor: colors.textPrimary,
      style: textStyle,
      contextMenuBuilder: contextMenuBuilder,
      decoration: InputDecoration(
        counterText: '',
        isDense: true,
        hintText: widget.hintText,
        hintStyle: textStyle.copyWith(color: colors.textTertiary),
        constraints: const BoxConstraints(minHeight: 34),
        prefixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(start: 12, end: 9),
          child: Icon(
            PhosphorIconsBold.magnifyingGlass,
            size: 16,
            color: colors.textTertiary,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 37),
        suffixIcon: hasText
            ? Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: _SettingsSearchClearButton(
                  label: StarLocalizations.of(
                    context,
                  ).userSettingsSearchClear,
                  onTap: _clearAndRefocus,
                ),
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 36),
        filled: true,
        fillColor: starFormSurfaceBackground(context),
        contentPadding: EdgeInsetsDirectional.fromSTEB(
          0,
          8,
          hasText ? 13 : 17,
          8,
        ),
        border: idleBorder,
        enabledBorder: idleBorder,
        disabledBorder: idleBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: starCssColorMix(
              colors.backgroundModifierAccent,
              colors.textTertiary,
              0.72,
            ),
          ),
        ),
      ),
    );
  }

  void _clearAndRefocus() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onCleared?.call();
    _focusNode.requestFocus();
  }

  Color _resolveSearchInputFillColor(
    BuildContext context,
    StarColorTheme colors,
  ) {
    if (Theme.of(context).brightness == Brightness.light) {
      return Color.lerp(colors.backgroundPrimary, Colors.black, 0.06)!;
    }
    return Color.lerp(colors.backgroundSecondaryAlt, Colors.black, 0.12)!;
  }

  Widget? _renderRightElement(StarColorTheme colors, String text) {
    if (widget.rightCustomElement == null && text.isEmpty) {
      return null;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.rightCustomElement != null)
          Padding(
            padding: EdgeInsetsDirectional.only(end: text.isEmpty ? 8 : 0),
            child: widget.rightCustomElement,
          ),
        if (text.isNotEmpty)
          Semantics(
            button: true,
            label: StarLocalizations.of(context).userSettingsSearchClear,
            child: StarGestureDetector(
              onTap: _clear,
              behavior: HitTestBehavior.opaque,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 12, 7, 12),
                  child: Icon(
                    PhosphorIconsFill.xCircle,
                    size: 16,
                    color: colors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SettingsSearchClearButton extends StatelessWidget {
  const _SettingsSearchClearButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return StarButton.desktop(
      icon: PhosphorIconsBold.x,
      semanticLabel: label,
      onPressed: onTap,
      extent: 28,
      iconSize: 14,
      borderRadius: 6,
      color: colors.textTertiary,
      hoverBackground: colors.surfaceInteractiveHoverBg,
      border: Colors.transparent,
      hoverBorder: starCssColorMix(
        colors.backgroundModifierAccent,
        colors.textTertiary,
        0.72,
      ),
      duration: const Duration(milliseconds: 120),
    );
  }
}
