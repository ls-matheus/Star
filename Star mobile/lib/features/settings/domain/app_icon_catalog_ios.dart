import 'package:star_app/core/build/app_build_config.dart';
import 'package:star_app/features/settings/domain/app_icon_choice.dart';
import 'package:star_app/features/settings/domain/app_icon_preview_assets.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';

const String kIosStarfieldAlternateIconName = 'AppIconStarfield';
const String kIosSwedenAlternateIconName = 'AppIconSweden';
const String kIosGreyscaleAlternateIconName = 'AppIconGreyscale';
const String kIosRainbowAlternateIconName = 'AppIconRainbow';
const String kIosWavesAlternateIconName = 'AppIconWaves';
const String kIosChromaticAberrationAlternateIconName =
    'AppIconChromaticAberration';
const String kIosDefaultBrutalistAlternateIconName = 'AppIconDefaultBrutalist';
const String kIosGreyscaleBrutalistAlternateIconName =
    'AppIconGreyscaleBrutalist';
const String kIosCanaryBrutalistAlternateIconName = 'AppIconCanaryBrutalist';

AppIconChoice _iosDefaultBrutalistAppIconChoice() {
  if (AppBuildConfig.isCanary) {
    return AppIconChoice(
      alternateIconName: kIosCanaryBrutalistAlternateIconName,
      previewAssetPath: AppIconPreviewAssets.iosCanaryBrutalist,
      label: (StarLocalizations l10n) => l10n.appIconOptionDefaultBrutalist,
    );
  }
  return AppIconChoice(
    alternateIconName: kIosDefaultBrutalistAlternateIconName,
    previewAssetPath: AppIconPreviewAssets.iosDefaultBrutalist,
    label: (StarLocalizations l10n) => l10n.appIconOptionDefaultBrutalist,
  );
}

List<AppIconChoice> iosAppIconChoiceCatalog() {
  return [
    AppIconChoice(
      alternateIconName: null,
      previewAssetPath: appIconPreviewIosDefault(),
      label: (StarLocalizations l10n) => l10n.appIconOptionDefault,
    ),
    AppIconChoice(
      alternateIconName: kIosStarfieldAlternateIconName,
      previewAssetPath: AppIconPreviewAssets.iosStarfield,
      label: (StarLocalizations l10n) => l10n.appIconOptionStarfield,
    ),
    AppIconChoice(
      alternateIconName: kIosSwedenAlternateIconName,
      previewAssetPath: AppIconPreviewAssets.iosSweden,
      label: (StarLocalizations l10n) => l10n.appIconOptionSweden,
    ),
    AppIconChoice(
      alternateIconName: kIosGreyscaleAlternateIconName,
      previewAssetPath: AppIconPreviewAssets.iosGreyscale,
      label: (StarLocalizations l10n) => l10n.appIconOptionGreyscale,
    ),
    AppIconChoice(
      alternateIconName: kIosRainbowAlternateIconName,
      previewAssetPath: AppIconPreviewAssets.iosRainbow,
      label: (StarLocalizations l10n) => l10n.appIconOptionRainbow,
    ),
    AppIconChoice(
      alternateIconName: kIosWavesAlternateIconName,
      previewAssetPath: AppIconPreviewAssets.iosWaves,
      label: (StarLocalizations l10n) => l10n.appIconOptionWaves,
    ),
    AppIconChoice(
      alternateIconName: kIosChromaticAberrationAlternateIconName,
      previewAssetPath: AppIconPreviewAssets.iosChromaticAberration,
      label: (StarLocalizations l10n) =>
          l10n.appIconOptionChromaticAberration,
    ),
    _iosDefaultBrutalistAppIconChoice(),
    AppIconChoice(
      alternateIconName: kIosGreyscaleBrutalistAlternateIconName,
      previewAssetPath: AppIconPreviewAssets.iosGreyscaleBrutalist,
      label: (StarLocalizations l10n) => l10n.appIconOptionGreyscaleBrutalist,
    ),
  ];
}
