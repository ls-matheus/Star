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

List<AppIconChoice> androidAppIconChoiceCatalog() {
  // The only promoted icon is the supplied white-star-on-gold design.
  // Other Android activity aliases are kept for existing installations.
  return [
    AppIconChoice(
      alternateIconName: null,
      previewAssetPath: appIconPreviewAndroidDefault(),
      label: (StarLocalizations l10n) => l10n.appIconOptionDefault,
    ),
  ];
}
