import 'package:star_app/core/build/app_build_config.dart';
import 'package:star_app/features/settings/domain/app_icon_choice.dart';
import 'package:star_app/features/settings/domain/app_icon_preview_assets.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';

const String kAndroidStarfieldAlternateIconName = 'starfield';
const String kAndroidSwedenAlternateIconName = 'sweden';
const String kAndroidGreyscaleAlternateIconName = 'greyscale';
const String kAndroidRainbowAlternateIconName = 'rainbow';
const String kAndroidWavesAlternateIconName = 'waves';
const String kAndroidChromaticAberrationAlternateIconName =
    'chromatic_aberration';
const String kAndroidDefaultBrutalistAlternateIconName = 'default_brutalist';
const String kAndroidGreyscaleBrutalistAlternateIconName =
    'greyscale_brutalist';
const String kAndroidCanaryBrutalistAlternateIconName =
    'default_canary_brutalist';

AppIconChoice _androidDefaultBrutalistAppIconChoice() {
  if (AppBuildConfig.isCanary) {
    return AppIconChoice(
      alternateIconName: kAndroidCanaryBrutalistAlternateIconName,
      previewAssetPath: AppIconPreviewAssets.androidCanaryBrutalist,
      label: (StarLocalizations l10n) => l10n.appIconOptionDefaultBrutalist,
    );
  }
  return AppIconChoice(
    alternateIconName: kAndroidDefaultBrutalistAlternateIconName,
    previewAssetPath: AppIconPreviewAssets.androidDefaultBrutalist,
    label: (StarLocalizations l10n) => l10n.appIconOptionDefaultBrutalist,
  );
}

List<AppIconChoice> androidAppIconChoiceCatalog() {
  return [
    AppIconChoice(
      alternateIconName: null,
      previewAssetPath: appIconPreviewAndroidDefault(),
      label: (StarLocalizations l10n) => l10n.appIconOptionDefault,
    ),
    AppIconChoice(
      alternateIconName: kAndroidStarfieldAlternateIconName,
      previewAssetPath: AppIconPreviewAssets.androidStarfield,
      label: (StarLocalizations l10n) => l10n.appIconOptionStarfield,
    ),
    AppIconChoice(
      alternateIconName: kAndroidSwedenAlternateIconName,
      previewAssetPath: AppIconPreviewAssets.androidSweden,
      label: (StarLocalizations l10n) => l10n.appIconOptionSweden,
    ),
    AppIconChoice(
      alternateIconName: kAndroidGreyscaleAlternateIconName,
      previewAssetPath: AppIconPreviewAssets.androidGreyscale,
      label: (StarLocalizations l10n) => l10n.appIconOptionGreyscale,
    ),
    AppIconChoice(
      alternateIconName: kAndroidRainbowAlternateIconName,
      previewAssetPath: AppIconPreviewAssets.androidRainbow,
      label: (StarLocalizations l10n) => l10n.appIconOptionRainbow,
    ),
    AppIconChoice(
      alternateIconName: kAndroidWavesAlternateIconName,
      previewAssetPath: AppIconPreviewAssets.androidWaves,
      label: (StarLocalizations l10n) => l10n.appIconOptionWaves,
    ),
    AppIconChoice(
      alternateIconName: kAndroidChromaticAberrationAlternateIconName,
      previewAssetPath: AppIconPreviewAssets.androidChromaticAberration,
      label: (StarLocalizations l10n) =>
          l10n.appIconOptionChromaticAberration,
    ),
    _androidDefaultBrutalistAppIconChoice(),
    AppIconChoice(
      alternateIconName: kAndroidGreyscaleBrutalistAlternateIconName,
      previewAssetPath: AppIconPreviewAssets.androidGreyscaleBrutalist,
      label: (StarLocalizations l10n) => l10n.appIconOptionGreyscaleBrutalist,
    ),
  ];
}
