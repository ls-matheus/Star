import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/chat/presentation/widgets/pickers/picker_search_input.dart';
import 'package:star_app/features/discovery/presentation/widgets/discovery_language_select.dart';
import 'package:star_app/features/discovery/providers/discovery_controller.dart';
import 'package:star_app/features/ui/select/star_select.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

const double discoveryFiltersMaxContentWidth = 400;

class DiscoveryFilters extends ConsumerStatefulWidget {
  const DiscoveryFilters({
    this.autofocusSearch = false,
    this.showLanguageFilter = true,
    this.maxContentWidth,
    super.key,
  });

  final bool autofocusSearch;
  final bool showLanguageFilter;
  final double? maxContentWidth;

  @override
  ConsumerState<DiscoveryFilters> createState() => _DiscoveryFiltersState();
}

class _DiscoveryFiltersState extends ConsumerState<DiscoveryFilters> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;
    final l10n = StarLocalizations.of(context);
    final DiscoveryState state = ref.watch(discoveryControllerProvider);
    final List<StarSelectItem<String?>> languageItems =
        buildDiscoveryLanguageSelectItems(l10n);
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TapRegion(
          onTapOutside: (_) => _searchFocusNode.unfocus(),
          child: PickerSearchInput.inline(
            controller: _searchController,
            focusNode: _searchFocusNode,
            hintText: l10n.discoverySearchCommunities,
            autofocus: widget.autofocusSearch,
            onChanged: ref.read(discoveryControllerProvider.notifier).setQuery,
          ),
        ),
        if (widget.showLanguageFilter) ...<Widget>[
          SizedBox(height: layout.s2),
          StarSelect<String?>(
            value: state.language,
            label: l10n.discoveryFilterByLanguage,
            hint: l10n.discoveryAllLanguages,
            items: languageItems,
            stretch: true,
            onChanged: ref
                .read(discoveryControllerProvider.notifier)
                .setLanguage,
          ),
        ],
      ],
    );
    final double? maxContentWidth = widget.maxContentWidth;
    if (maxContentWidth != null) {
      content = Align(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: content,
        ),
      );
    }
    return Container(
      color: colors.brandPrimary,
      padding: EdgeInsets.fromLTRB(layout.s4, 0, layout.s4, layout.s4),
      child: content,
    );
  }
}
