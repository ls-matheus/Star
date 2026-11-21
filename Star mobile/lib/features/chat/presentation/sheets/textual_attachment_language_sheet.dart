import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/chat/presentation/widgets/pickers/picker_search_input.dart';
import 'package:star_app/features/chat/utils/attachments/preview_language_options.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/desktop_surface/star_desktop_surface.dart';
import 'package:star_app/features/ui/selected_check/star_selected_check.dart';
import 'package:star_app/features/ui/tappable/star_tappable.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

Future<String?> showTextualAttachmentLanguageSheet({
  required BuildContext context,
  required String selectedLanguage,
  required String inferredLanguageCode,
}) {
  final StarLocalizations l10n = StarLocalizations.of(context);
  return StarBottomSheet.showScrollable<String>(
    context,
    title: l10n.chatTextualPreviewSyntaxHighlighting,
    initialChildSize: StarBottomSheet.scrollableSheetHalfSize,
    desktop: const StarDesktopPresentation(
      surface: StarDesktopSurface.menu,
    ),
    minChildSize: 0.45,
    builder:
        (
          BuildContext sheetContext,
          ScrollController scrollController,
          VoidCallback close,
        ) {
          return _TextualAttachmentLanguageSheetBody(
            selectedLanguage: selectedLanguage,
            inferredLanguageCode: inferredLanguageCode,
            scrollController: scrollController,
            onSelect: (String language) {
              Navigator.of(sheetContext).pop(language);
            },
          );
        },
  );
}

class _TextualAttachmentLanguageSheetBody extends StatefulWidget {
  const _TextualAttachmentLanguageSheetBody({
    required this.selectedLanguage,
    required this.inferredLanguageCode,
    required this.scrollController,
    required this.onSelect,
  });

  final String selectedLanguage;
  final String inferredLanguageCode;
  final ScrollController scrollController;
  final ValueChanged<String> onSelect;

  @override
  State<_TextualAttachmentLanguageSheetBody> createState() =>
      _TextualAttachmentLanguageSheetBodyState();
}

class _TextualAttachmentLanguageSheetBodyState
    extends State<_TextualAttachmentLanguageSheetBody> {
  late final TextEditingController _searchController;
  late final List<PreviewLanguageOption> _options;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _options = buildPreviewLanguageOptions(
      inferredLanguageCode: widget.inferredLanguageCode,
      selectedLanguage: widget.selectedLanguage,
    );
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _labelFor(PreviewLanguageOption option, StarLocalizations l10n) {
    if (option.code == 'plaintext') {
      return l10n.chatTextualPreviewLanguagePlaintext;
    }
    return option.code;
  }

  String? _secondaryFor(PreviewLanguageOption option) {
    if (!option.hasSecondaryName) {
      return null;
    }
    return option.canonicalCode.toUpperCase();
  }

  bool _matchesQuery(PreviewLanguageOption option, String query) {
    if (query.isEmpty) {
      return true;
    }
    return option.code.contains(query) || option.canonicalCode.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;
    final StarLocalizations l10n = StarLocalizations.of(context);
    final String query = _query.trim().toLowerCase();
    final List<PreviewLanguageOption> filtered = query.isEmpty
        ? _options
        : _options
              .where(
                (PreviewLanguageOption option) => _matchesQuery(option, query),
              )
              .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StarBottomSheetSection(
          child: PickerSearchInput.inline(
            controller: _searchController,
            hintText: l10n.chatTextualPreviewSearchLanguage,
            onChanged: (String value) => setState(() => _query = value),
          ),
        ),
        SizedBox(height: layout.s3),
        Expanded(
          child: filtered.isEmpty
              ? StarBottomSheetContent(
                  scrollable: false,
                  child: Center(
                    child: Text(
                      l10n.chatTextualPreviewNoLanguagesFound,
                      style: context.textStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                )
              : ListView(
                  controller: widget.scrollController,
                  padding: StarBottomSheet.scrollViewPadding(context),
                  children: [
                    StarBottomSheetSection(
                      child: StarMenuGroup(
                        children: [
                          for (final PreviewLanguageOption option in filtered)
                            _LanguageOptionItem(
                              label: _labelFor(option, l10n),
                              secondaryName: _secondaryFor(option),
                              isSelected:
                                  option.code == widget.selectedLanguage,
                              onTap: () => widget.onSelect(option.code),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _LanguageOptionItem extends StatelessWidget {
  const _LanguageOptionItem({
    required this.label,
    required this.onTap,
    required this.isSelected,
    this.secondaryName,
  });

  final String label;
  final String? secondaryName;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color baseColor = isSelected
        ? colors.brandPrimary
        : colors.textPrimary;
    final String semanticLabel = secondaryName == null
        ? label
        : '$label. $secondaryName';

    return StarTappable(
      onTap: onTap,
      selected: isSelected,
      semanticLabel: semanticLabel,
      excludeChildSemantics: true,
      builder: (BuildContext context, Set<WidgetState> states) {
        final bool isPressed = states.contains(WidgetState.pressed);
        return AnimatedContainer(
          duration: context.motion.fast,
          curve: context.motion.curve,
          color: isSelected
              ? colors.brandPrimary.withValues(alpha: 0.12)
              : isPressed
              ? colors.backgroundModifierHover.withValues(alpha: 0.6)
              : Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.smallText.copyWith(
                              color: baseColor,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (secondaryName != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              secondaryName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.smallText.copyWith(
                                color: colors.textTertiary,
                                fontSize: 11,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 12),
                    const StarSelectedCheck(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
