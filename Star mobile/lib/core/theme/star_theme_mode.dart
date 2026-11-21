enum StarThemeMode {
  dark,
  darkLegacy,
  light,
  coal,
  system;

  String get apiValue => switch (this) {
    StarThemeMode.dark => 'dark',
    StarThemeMode.darkLegacy => 'dark_legacy',
    StarThemeMode.light => 'light',
    StarThemeMode.coal => 'coal',
    StarThemeMode.system => 'system',
  };

  static StarThemeMode? fromApiValue(String raw) => switch (raw) {
    'dark' => StarThemeMode.dark,
    'dark_legacy' || 'darkLegacy' => StarThemeMode.darkLegacy,
    'light' => StarThemeMode.light,
    'coal' => StarThemeMode.coal,
    'system' => StarThemeMode.system,
    _ => null,
  };
}
