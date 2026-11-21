import 'package:star_app/features/discovery/domain/discovery_category_labels.dart';
import 'package:star_app/features/discovery/domain/discovery_constants.dart';
import 'package:star_app/features/discovery/domain/discovery_supported_languages.dart';
import 'package:star_app/features/ui/select/star_select.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';

List<StarSelectItem<int>> discoveryCategorySelectItems(
  StarLocalizations l10n,
) {
  return List<StarSelectItem<int>>.generate(
    9,
    (int index) => StarSelectItem<int>(
      value: index,
      label: discoveryCategoryLabel(l10n, index) ?? '$index',
    ),
  );
}

List<StarSelectItem<String>> discoveryLanguageSelectItems() {
  return sortedDiscoveryLanguages()
      .map(
        (DiscoveryLanguage language) => StarSelectItem<String>(
          value: language.code,
          label: language.displayLabel,
          searchText:
              '${language.name} ${language.nativeName} ${language.code}',
        ),
      )
      .toList();
}

String resolveDiscoveryPrimaryLanguage(String language) {
  final bool isSupported = sortedDiscoveryLanguages().any(
    (DiscoveryLanguage item) => item.code == language,
  );
  if (isSupported) {
    return language;
  }
  return DiscoveryConstants.defaultLanguage;
}

String? validateDiscoveryDescription(
  StarLocalizations l10n,
  String description,
) {
  final String trimmed = description.trim();
  if (trimmed.isEmpty) {
    return l10n.guildSettingsDiscoveryDescriptionRequired;
  }
  if (trimmed.length < DiscoveryConstants.descriptionMinLength) {
    return l10n.guildSettingsDiscoveryDescriptionMinLength(
      DiscoveryConstants.descriptionMinLength,
    );
  }
  if (trimmed.length > DiscoveryConstants.descriptionMaxLength) {
    return l10n.guildSettingsDiscoveryDescriptionMaxLength(
      DiscoveryConstants.descriptionMaxLength,
    );
  }
  return null;
}
