import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/material_ui.dart';

const Map<String, String> kThemeCssVariableToProperty = {
  '--accent-danger': 'accentDanger',
  '--accent-info': 'accentInfo',
  '--accent-primary': 'accentPrimary',
  '--accent-purple': 'accentPurple',
  '--accent-success': 'accentSuccess',
  '--accent-warning': 'accentWarning',
  '--alert-caution': 'alertCaution',
  '--alert-caution-color': 'alertCaution',
  '--alert-important': 'alertImportant',
  '--alert-important-color': 'alertImportant',
  '--alert-note': 'alertNote',
  '--alert-note-color': 'alertNote',
  '--alert-tip': 'alertTip',
  '--alert-tip-color': 'alertTip',
  '--alert-warning': 'alertWarning',
  '--alert-warning-color': 'alertWarning',
  '--background-channel-header': 'backgroundChannelHeader',
  '--background-floating': 'backgroundFloating',
  '--background-header-primary': 'backgroundHeaderPrimary',
  '--background-header-primary-hover': 'backgroundHeaderPrimaryHover',
  '--background-header-secondary': 'backgroundHeaderSecondary',
  '--background-modifier-accent': 'backgroundModifierAccent',
  '--background-modifier-accent-focus': 'backgroundModifierAccentFocus',
  '--background-modifier-hover': 'backgroundModifierHover',
  '--background-modifier-selected': 'backgroundModifierSelected',
  '--background-primary': 'backgroundPrimary',
  '--background-secondary': 'backgroundSecondary',
  '--background-secondary-alt': 'backgroundSecondaryAlt',
  '--background-secondary-lighter': 'backgroundSecondaryLighter',
  '--background-tertiary': 'backgroundTertiary',
  '--background-textarea': 'backgroundTextarea',
  '--bg-code': 'bgCode',
  '--bg-code-block': 'bgCodeBlock',
  '--bg-primary': 'backgroundPrimary',
  '--bg-secondary': 'backgroundSecondary',
  '--bg-table-header': 'bgTableHeader',
  '--bg-table-row-even': 'bgTableRowEven',
  '--bg-table-row-odd': 'bgTableRowOdd',
  '--bg-tertiary': 'backgroundTertiary',
  '--border-color': 'borderColor',
  '--border-color-focus': 'borderColorFocus',
  '--border-color-hover': 'borderColorHover',
  '--brand-primary': 'brandPrimary',
  '--brand-primary-fill': 'brandPrimaryFill',
  '--brand-primary-light': 'brandPrimaryLight',
  '--brand-secondary': 'brandSecondary',
  '--button-danger-active-fill': 'buttonDangerActiveFill',
  '--button-danger-fill': 'buttonDangerFill',
  '--button-danger-outline-active-fill': 'buttonDangerOutlineActiveFill',
  '--button-danger-outline-border': 'buttonDangerOutlineBorder',
  '--button-danger-outline-text': 'buttonDangerOutlineText',
  '--button-danger-text': 'buttonDangerText',
  '--button-ghost-text': 'buttonGhostText',
  '--button-inverted-fill': 'buttonInvertedFill',
  '--button-inverted-text': 'buttonInvertedText',
  '--button-outline-active-fill': 'buttonOutlineActiveFill',
  '--button-outline-border': 'buttonOutlineBorder',
  '--button-outline-text': 'buttonOutlineText',
  '--button-primary-active-fill': 'buttonPrimaryActiveFill',
  '--button-primary-fill': 'buttonPrimaryFill',
  '--button-primary-text': 'buttonPrimaryText',
  '--button-secondary-active-fill': 'buttonSecondaryActiveFill',
  '--button-secondary-active-text': 'buttonSecondaryActiveText',
  '--button-secondary-fill': 'buttonSecondaryFill',
  '--button-secondary-text': 'buttonSecondaryText',
  '--channel-sidebar-background': 'channelSidebarBackground',
  '--chat-background': 'chatBackground',
  '--chat-input-background': 'chatInputBackground',
  '--control-button-active-bg': 'controlButtonActiveBg',
  '--control-button-active-text': 'controlButtonActiveText',
  '--control-button-danger-hover-bg': 'controlButtonDangerHoverBg',
  '--control-button-danger-text': 'controlButtonDangerText',
  '--control-button-hover-bg': 'controlButtonHoverBg',
  '--control-button-hover-text': 'controlButtonHoverText',
  '--control-button-normal-bg': 'controlButtonNormalBg',
  '--control-button-normal-text': 'controlButtonNormalText',
  '--embed-background': 'embedBackground',
  '--embed-border': 'embedBorder',
  '--focus-primary': 'focusPrimary',
  '--form-surface-background': 'buttonSecondaryFill',
  '--guild-banner-gradient': 'guildBannerGradient',
  '--guild-list-foreground': 'guildListForeground',
  '--interactive-active': 'interactiveActive',
  '--interactive-hover': 'interactiveHover',
  '--interactive-muted': 'interactiveMuted',
  '--interactive-normal': 'interactiveNormal',
  '--list-item-selected-bg': 'listItemSelectedBg',
  '--list-item-selected-border': 'listItemSelectedBorder',
  '--list-item-pressed-bg': 'listItemPressedBg',
  '--markup-everyone-border': 'markupEveryoneBorder',
  '--markup-everyone-fill': 'markupEveryoneFill',
  '--markup-everyone-text': 'markupEveryoneText',
  '--markup-here-border': 'markupHereBorder',
  '--markup-here-fill': 'markupHereFill',
  '--markup-here-text': 'markupHereText',
  '--markup-interactive-hover-fill': 'markupInteractiveHoverFill',
  '--markup-interactive-hover-text': 'markupInteractiveHoverText',
  '--markup-jump-link-fill': 'markupJumpLinkFill',
  '--markup-jump-link-hover-fill': 'markupJumpLinkHoverFill',
  '--markup-jump-link-text': 'markupJumpLinkText',
  '--markup-mention-border': 'markupMentionBorder',
  '--markup-mention-fill': 'markupMentionFill',
  '--markup-mention-text': 'markupMentionText',
  '--member-list-background': 'memberListBackground',
  '--mention-background': 'mentionBackground',
  '--menu-danger-text': 'menuDangerText',
  '--modal-scrim': 'modalScrim',
  '--panel-control-bg': 'panelControlBg',
  '--panel-control-border': 'panelControlBorder',
  '--panel-control-divider': 'panelControlDivider',
  '--panel-control-highlight': 'panelControlHighlight',
  '--scrollbar-thumb-bg': 'scrollbarThumbBg',
  '--scrollbar-thumb-bg-hover': 'scrollbarThumbBgHover',
  '--scrollbar-track-bg': 'scrollbarTrackBg',
  '--server-icon-active': 'serverIconActive',
  '--server-icon-background': 'serverIconBackground',
  '--server-sidebar-background': 'serverSidebarBackground',
  '--spoiler-background': 'spoilerBackground',
  '--spoiler-overlay-color': 'spoilerBackground',
  '--spoiler-overlay-hover-color': 'spoilerOverlayHoverColor',
  '--status-danger': 'statusDanger',
  '--status-dnd': 'statusDnd',
  '--status-idle': 'statusIdle',
  '--status-offline': 'statusOffline',
  '--status-online': 'statusOnline',
  '--status-warning': 'statusWarning',
  '--surface-interactive-hover-bg': 'surfaceInteractiveHoverBg',
  '--surface-interactive-selected-bg': 'surfaceInteractiveSelectedBg',
  '--surface-interactive-selected-color': 'surfaceInteractiveSelectedColor',
  '--switch-thumb': 'switchThumb',
  '--switch-thumb-checked-icon': 'switchThumbCheckedIcon',
  '--switch-thumb-unchecked-icon': 'switchThumbUncheckedIcon',
  '--switch-track-inactive': 'switchTrackInactive',
  '--text-chat': 'textChat',
  '--text-chat-muted': 'textChatMuted',
  '--text-code': 'textCode',
  '--text-danger': 'textDanger',
  '--text-link': 'textLink',
  '--text-on-brand-primary': 'textOnBrandPrimary',
  '--text-positive': 'textPositive',
  '--text-primary': 'textPrimary',
  '--text-primary-muted': 'textPrimaryMuted',
  '--text-secondary': 'textSecondary',
  '--text-selection': 'textSelection',
  '--text-tertiary': 'textTertiary',
  '--text-tertiary-muted': 'textTertiaryMuted',
  '--text-tertiary-secondary': 'textTertiarySecondary',
  '--text-warning': 'textWarning',
  '--user-area-divider-color': 'userAreaDividerColor',
  '--user-panel-background': 'userPanelBackground',
};

final RegExp _cssVarReferencePattern = RegExp(
  r'var\(\s*(--[a-zA-Z0-9_-]+)\s*\)',
  caseSensitive: false,
);

final Map<String, Color Function(StarColorTheme)> kThemePropertyColorReaders =
    <String, Color Function(StarColorTheme)>{
      'backgroundPrimary': (StarColorTheme t) => t.backgroundPrimary,
      'backgroundSecondary': (StarColorTheme t) => t.backgroundSecondary,
      'backgroundSecondaryLighter': (StarColorTheme t) =>
          t.backgroundSecondaryLighter,
      'backgroundSecondaryAlt': (StarColorTheme t) =>
          t.backgroundSecondaryAlt,
      'backgroundTertiary': (StarColorTheme t) => t.backgroundTertiary,
      'backgroundTextarea': (StarColorTheme t) => t.backgroundTextarea,
      'backgroundHeaderPrimary': (StarColorTheme t) =>
          t.backgroundHeaderPrimary,
      'backgroundHeaderPrimaryHover': (StarColorTheme t) =>
          t.backgroundHeaderPrimaryHover,
      'backgroundHeaderSecondary': (StarColorTheme t) =>
          t.backgroundHeaderSecondary,
      'backgroundChannelHeader': (StarColorTheme t) =>
          t.backgroundChannelHeader,
      'backgroundFloating': (StarColorTheme t) => t.backgroundFloating,
      'guildListForeground': (StarColorTheme t) => t.guildListForeground,
      'backgroundModifierHover': (StarColorTheme t) =>
          t.backgroundModifierHover,
      'backgroundModifierSelected': (StarColorTheme t) =>
          t.backgroundModifierSelected,
      'backgroundModifierAccent': (StarColorTheme t) =>
          t.backgroundModifierAccent,
      'backgroundModifierAccentFocus': (StarColorTheme t) =>
          t.backgroundModifierAccentFocus,
      'brandPrimary': (StarColorTheme t) => t.brandPrimary,
      'brandSecondary': (StarColorTheme t) => t.brandSecondary,
      'brandPrimaryLight': (StarColorTheme t) => t.brandPrimaryLight,
      'brandPrimaryFill': (StarColorTheme t) => t.brandPrimaryFill,
      'statusOnline': (StarColorTheme t) => t.statusOnline,
      'statusIdle': (StarColorTheme t) => t.statusIdle,
      'statusDnd': (StarColorTheme t) => t.statusDnd,
      'statusOffline': (StarColorTheme t) => t.statusOffline,
      'statusDanger': (StarColorTheme t) => t.statusDanger,
      'statusWarning': (StarColorTheme t) => t.statusWarning,
      'textPrimary': (StarColorTheme t) => t.textPrimary,
      'textSecondary': (StarColorTheme t) => t.textSecondary,
      'textTertiary': (StarColorTheme t) => t.textTertiary,
      'textPrimaryMuted': (StarColorTheme t) => t.textPrimaryMuted,
      'textChat': (StarColorTheme t) => t.textChat,
      'textChatMuted': (StarColorTheme t) => t.textChatMuted,
      'textLink': (StarColorTheme t) => t.textLink,
      'textOnBrandPrimary': (StarColorTheme t) => t.textOnBrandPrimary,
      'textTertiaryMuted': (StarColorTheme t) => t.textTertiaryMuted,
      'textTertiarySecondary': (StarColorTheme t) => t.textTertiarySecondary,
      'textWarning': (StarColorTheme t) => t.textWarning,
      'textDanger': (StarColorTheme t) => t.textDanger,
      'textPositive': (StarColorTheme t) => t.textPositive,
      'textCode': (StarColorTheme t) => t.textCode,
      'borderColor': (StarColorTheme t) => t.borderColor,
      'borderColorHover': (StarColorTheme t) => t.borderColorHover,
      'borderColorFocus': (StarColorTheme t) => t.borderColorFocus,
      'accentPrimary': (StarColorTheme t) => t.accentPrimary,
      'accentSuccess': (StarColorTheme t) => t.accentSuccess,
      'accentWarning': (StarColorTheme t) => t.accentWarning,
      'accentDanger': (StarColorTheme t) => t.accentDanger,
      'accentInfo': (StarColorTheme t) => t.accentInfo,
      'accentPurple': (StarColorTheme t) => t.accentPurple,
      'alertNote': (StarColorTheme t) => t.alertNote,
      'alertTip': (StarColorTheme t) => t.alertTip,
      'alertImportant': (StarColorTheme t) => t.alertImportant,
      'alertWarning': (StarColorTheme t) => t.alertWarning,
      'alertCaution': (StarColorTheme t) => t.alertCaution,
      'markupMentionText': (StarColorTheme t) => t.markupMentionText,
      'markupMentionFill': (StarColorTheme t) => t.markupMentionFill,
      'markupMentionBorder': (StarColorTheme t) => t.markupMentionBorder,
      'markupInteractiveHoverText': (StarColorTheme t) =>
          t.markupInteractiveHoverText,
      'markupInteractiveHoverFill': (StarColorTheme t) =>
          t.markupInteractiveHoverFill,
      'markupJumpLinkText': (StarColorTheme t) => t.markupJumpLinkText,
      'markupJumpLinkFill': (StarColorTheme t) => t.markupJumpLinkFill,
      'markupJumpLinkHoverFill': (StarColorTheme t) =>
          t.markupJumpLinkHoverFill,
      'markupEveryoneText': (StarColorTheme t) => t.markupEveryoneText,
      'markupEveryoneFill': (StarColorTheme t) => t.markupEveryoneFill,
      'markupEveryoneBorder': (StarColorTheme t) => t.markupEveryoneBorder,
      'markupHereText': (StarColorTheme t) => t.markupHereText,
      'markupHereFill': (StarColorTheme t) => t.markupHereFill,
      'markupHereBorder': (StarColorTheme t) => t.markupHereBorder,
      'buttonPrimaryFill': (StarColorTheme t) => t.buttonPrimaryFill,
      'buttonPrimaryActiveFill': (StarColorTheme t) =>
          t.buttonPrimaryActiveFill,
      'buttonPrimaryText': (StarColorTheme t) => t.buttonPrimaryText,
      'buttonSecondaryFill': (StarColorTheme t) => t.buttonSecondaryFill,
      'buttonSecondaryActiveFill': (StarColorTheme t) =>
          t.buttonSecondaryActiveFill,
      'buttonSecondaryText': (StarColorTheme t) => t.buttonSecondaryText,
      'buttonSecondaryActiveText': (StarColorTheme t) =>
          t.buttonSecondaryActiveText,
      'buttonDangerFill': (StarColorTheme t) => t.buttonDangerFill,
      'buttonDangerActiveFill': (StarColorTheme t) =>
          t.buttonDangerActiveFill,
      'buttonDangerText': (StarColorTheme t) => t.buttonDangerText,
      'buttonDangerOutlineBorder': (StarColorTheme t) =>
          t.buttonDangerOutlineBorder,
      'buttonDangerOutlineText': (StarColorTheme t) =>
          t.buttonDangerOutlineText,
      'buttonDangerOutlineActiveFill': (StarColorTheme t) =>
          t.buttonDangerOutlineActiveFill,
      'buttonGhostText': (StarColorTheme t) => t.buttonGhostText,
      'buttonInvertedFill': (StarColorTheme t) => t.buttonInvertedFill,
      'buttonInvertedText': (StarColorTheme t) => t.buttonInvertedText,
      'buttonOutlineBorder': (StarColorTheme t) => t.buttonOutlineBorder,
      'buttonOutlineText': (StarColorTheme t) => t.buttonOutlineText,
      'buttonOutlineActiveFill': (StarColorTheme t) =>
          t.buttonOutlineActiveFill,
      'panelControlBg': (StarColorTheme t) => t.panelControlBg,
      'panelControlBorder': (StarColorTheme t) => t.panelControlBorder,
      'panelControlDivider': (StarColorTheme t) => t.panelControlDivider,
      'panelControlHighlight': (StarColorTheme t) => t.panelControlHighlight,
      'controlButtonNormalBg': (StarColorTheme t) => t.controlButtonNormalBg,
      'controlButtonNormalText': (StarColorTheme t) =>
          t.controlButtonNormalText,
      'controlButtonHoverBg': (StarColorTheme t) => t.controlButtonHoverBg,
      'controlButtonHoverText': (StarColorTheme t) =>
          t.controlButtonHoverText,
      'controlButtonActiveBg': (StarColorTheme t) => t.controlButtonActiveBg,
      'controlButtonActiveText': (StarColorTheme t) =>
          t.controlButtonActiveText,
      'controlButtonDangerText': (StarColorTheme t) =>
          t.controlButtonDangerText,
      'controlButtonDangerHoverBg': (StarColorTheme t) =>
          t.controlButtonDangerHoverBg,
      'switchTrackInactive': (StarColorTheme t) => t.switchTrackInactive,
      'switchThumb': (StarColorTheme t) => t.switchThumb,
      'switchThumbCheckedIcon': (StarColorTheme t) =>
          t.switchThumbCheckedIcon,
      'switchThumbUncheckedIcon': (StarColorTheme t) =>
          t.switchThumbUncheckedIcon,
      'menuDangerText': (StarColorTheme t) => t.menuDangerText,
      'bgCode': (StarColorTheme t) => t.bgCode,
      'bgCodeBlock': (StarColorTheme t) => t.bgCodeBlock,
      'bgTableHeader': (StarColorTheme t) => t.bgTableHeader,
      'bgTableRowOdd': (StarColorTheme t) => t.bgTableRowOdd,
      'bgTableRowEven': (StarColorTheme t) => t.bgTableRowEven,
      'surfaceInteractiveHoverBg': (StarColorTheme t) =>
          t.surfaceInteractiveHoverBg,
      'surfaceInteractiveSelectedBg': (StarColorTheme t) =>
          t.surfaceInteractiveSelectedBg,
      'surfaceInteractiveSelectedColor': (StarColorTheme t) =>
          t.surfaceInteractiveSelectedColor,
      'listItemSelectedBg': (StarColorTheme t) => t.listItemSelectedBg,
      'listItemSelectedBorder': (StarColorTheme t) =>
          t.listItemSelectedBorder,
      'listItemPressedBg': (StarColorTheme t) => t.listItemPressedBg,
      'scrollbarThumbBg': (StarColorTheme t) => t.scrollbarThumbBg,
      'scrollbarThumbBgHover': (StarColorTheme t) => t.scrollbarThumbBgHover,
      'scrollbarTrackBg': (StarColorTheme t) => t.scrollbarTrackBg,
      'textSelection': (StarColorTheme t) => t.textSelection,
      'chatBackground': (StarColorTheme t) => t.chatBackground,
      'chatInputBackground': (StarColorTheme t) => t.chatInputBackground,
      'serverSidebarBackground': (StarColorTheme t) =>
          t.serverSidebarBackground,
      'serverIconBackground': (StarColorTheme t) => t.serverIconBackground,
      'serverIconActive': (StarColorTheme t) => t.serverIconActive,
      'channelSidebarBackground': (StarColorTheme t) =>
          t.channelSidebarBackground,
      'memberListBackground': (StarColorTheme t) => t.memberListBackground,
      'userPanelBackground': (StarColorTheme t) => t.userPanelBackground,
      'userAreaDividerColor': (StarColorTheme t) => t.userAreaDividerColor,
      'embedBackground': (StarColorTheme t) => t.embedBackground,
      'embedBorder': (StarColorTheme t) => t.embedBorder,
      'mentionBackground': (StarColorTheme t) => t.mentionBackground,
      'spoilerBackground': (StarColorTheme t) => t.spoilerBackground,
      'spoilerOverlayHoverColor': (StarColorTheme t) =>
          t.spoilerOverlayHoverColor,
      'modalScrim': (StarColorTheme t) => t.modalScrim,
      'guildBannerGradient': (StarColorTheme t) => t.guildBannerGradient,
      'focusPrimary': (StarColorTheme t) => t.focusPrimary,
      'interactiveActive': (StarColorTheme t) => t.interactiveActive,
      'interactiveNormal': (StarColorTheme t) => t.interactiveNormal,
      'interactiveHover': (StarColorTheme t) => t.interactiveHover,
      'interactiveMuted': (StarColorTheme t) => t.interactiveMuted,
    };

Color readThemeColorProperty(StarColorTheme theme, String propertyName) {
  return kThemePropertyColorReaders[propertyName]!(theme);
}

String themeColorToCssHex(Color color) {
  String channel(double component) =>
      (component * 255).round().toRadixString(16).padLeft(2, '0');
  return '#${channel(color.r)}${channel(color.g)}${channel(color.b)}';
}

int themeColorToPickerInt(Color color) =>
    ((color.r * 255).round() << 16) |
    ((color.g * 255).round() << 8) |
    (color.b * 255).round();

Color themeColorFromPickerInt(int value) => Color.fromARGB(
  255,
  (value >> 16) & 0xFF,
  (value >> 8) & 0xFF,
  value & 0xFF,
);

String resolveCssVariableReferences(
  String value,
  Map<String, String> overrides,
  StarColorTheme base,
) {
  return value.replaceAllMapped(_cssVarReferencePattern, (Match match) {
    final String varName = match.group(1)!;
    if (overrides.containsKey(varName)) {
      return overrides[varName]!;
    }
    final String? propertyName = kThemeCssVariableToProperty[varName];
    if (propertyName == null) {
      return match.group(0)!;
    }
    return themeColorToCssHex(readThemeColorProperty(base, propertyName));
  });
}

Map<String, String> resolveCssOverrideValues(
  Map<String, String> rawOverrides,
  StarColorTheme base,
) {
  final Map<String, String> resolved = Map<String, String>.from(rawOverrides);
  for (var pass = 0; pass < 8; pass++) {
    var changed = false;
    for (final String key in resolved.keys.toList()) {
      final String next = resolveCssVariableReferences(
        resolved[key]!,
        resolved,
        base,
      );
      if (next != resolved[key]) {
        resolved[key] = next;
        changed = true;
      }
    }
    if (!changed) {
      break;
    }
  }
  return resolved;
}

extension StarColorThemeOverrideExtension on StarColorTheme {
  StarColorTheme applyPropertyOverrides(Map<String, Color> overrides) {
    if (overrides.isEmpty) {
      return this;
    }
    return copyWith(
      backgroundPrimary: overrides['backgroundPrimary'] ?? backgroundPrimary,
      backgroundSecondary:
          overrides['backgroundSecondary'] ?? backgroundSecondary,
      backgroundSecondaryLighter:
          overrides['backgroundSecondaryLighter'] ?? backgroundSecondaryLighter,
      backgroundSecondaryAlt:
          overrides['backgroundSecondaryAlt'] ?? backgroundSecondaryAlt,
      backgroundTertiary: overrides['backgroundTertiary'] ?? backgroundTertiary,
      backgroundTextarea: overrides['backgroundTextarea'] ?? backgroundTextarea,
      backgroundHeaderPrimary:
          overrides['backgroundHeaderPrimary'] ?? backgroundHeaderPrimary,
      backgroundHeaderPrimaryHover:
          overrides['backgroundHeaderPrimaryHover'] ??
          backgroundHeaderPrimaryHover,
      backgroundHeaderSecondary:
          overrides['backgroundHeaderSecondary'] ?? backgroundHeaderSecondary,
      backgroundChannelHeader:
          overrides['backgroundChannelHeader'] ?? backgroundChannelHeader,
      backgroundFloating: overrides['backgroundFloating'] ?? backgroundFloating,
      guildListForeground:
          overrides['guildListForeground'] ?? guildListForeground,
      backgroundModifierHover:
          overrides['backgroundModifierHover'] ?? backgroundModifierHover,
      backgroundModifierSelected:
          overrides['backgroundModifierSelected'] ?? backgroundModifierSelected,
      backgroundModifierAccent:
          overrides['backgroundModifierAccent'] ?? backgroundModifierAccent,
      backgroundModifierAccentFocus:
          overrides['backgroundModifierAccentFocus'] ??
          backgroundModifierAccentFocus,
      brandPrimary: overrides['brandPrimary'] ?? brandPrimary,
      brandSecondary: overrides['brandSecondary'] ?? brandSecondary,
      brandPrimaryLight: overrides['brandPrimaryLight'] ?? brandPrimaryLight,
      brandPrimaryFill: overrides['brandPrimaryFill'] ?? brandPrimaryFill,
      statusOnline: overrides['statusOnline'] ?? statusOnline,
      statusIdle: overrides['statusIdle'] ?? statusIdle,
      statusDnd: overrides['statusDnd'] ?? statusDnd,
      statusOffline: overrides['statusOffline'] ?? statusOffline,
      statusDanger: overrides['statusDanger'] ?? statusDanger,
      statusWarning: overrides['statusWarning'] ?? statusWarning,
      textPrimary: overrides['textPrimary'] ?? textPrimary,
      textSecondary: overrides['textSecondary'] ?? textSecondary,
      textTertiary: overrides['textTertiary'] ?? textTertiary,
      textPrimaryMuted: overrides['textPrimaryMuted'] ?? textPrimaryMuted,
      textChat: overrides['textChat'] ?? textChat,
      textChatMuted: overrides['textChatMuted'] ?? textChatMuted,
      textLink: overrides['textLink'] ?? textLink,
      textOnBrandPrimary: overrides['textOnBrandPrimary'] ?? textOnBrandPrimary,
      textTertiaryMuted: overrides['textTertiaryMuted'] ?? textTertiaryMuted,
      textTertiarySecondary:
          overrides['textTertiarySecondary'] ?? textTertiarySecondary,
      textWarning: overrides['textWarning'] ?? textWarning,
      textDanger: overrides['textDanger'] ?? textDanger,
      textPositive: overrides['textPositive'] ?? textPositive,
      textCode: overrides['textCode'] ?? textCode,
      borderColor: overrides['borderColor'] ?? borderColor,
      borderColorHover: overrides['borderColorHover'] ?? borderColorHover,
      borderColorFocus: overrides['borderColorFocus'] ?? borderColorFocus,
      accentPrimary: overrides['accentPrimary'] ?? accentPrimary,
      accentSuccess: overrides['accentSuccess'] ?? accentSuccess,
      accentWarning: overrides['accentWarning'] ?? accentWarning,
      accentDanger: overrides['accentDanger'] ?? accentDanger,
      accentInfo: overrides['accentInfo'] ?? accentInfo,
      accentPurple: overrides['accentPurple'] ?? accentPurple,
      alertNote: overrides['alertNote'] ?? alertNote,
      alertTip: overrides['alertTip'] ?? alertTip,
      alertImportant: overrides['alertImportant'] ?? alertImportant,
      alertWarning: overrides['alertWarning'] ?? alertWarning,
      alertCaution: overrides['alertCaution'] ?? alertCaution,
      markupMentionText: overrides['markupMentionText'] ?? markupMentionText,
      markupMentionFill: overrides['markupMentionFill'] ?? markupMentionFill,
      markupMentionBorder:
          overrides['markupMentionBorder'] ?? markupMentionBorder,
      markupInteractiveHoverText:
          overrides['markupInteractiveHoverText'] ?? markupInteractiveHoverText,
      markupInteractiveHoverFill:
          overrides['markupInteractiveHoverFill'] ?? markupInteractiveHoverFill,
      markupJumpLinkText: overrides['markupJumpLinkText'] ?? markupJumpLinkText,
      markupJumpLinkFill: overrides['markupJumpLinkFill'] ?? markupJumpLinkFill,
      markupJumpLinkHoverFill:
          overrides['markupJumpLinkHoverFill'] ?? markupJumpLinkHoverFill,
      markupEveryoneText: overrides['markupEveryoneText'] ?? markupEveryoneText,
      markupEveryoneFill: overrides['markupEveryoneFill'] ?? markupEveryoneFill,
      markupEveryoneBorder:
          overrides['markupEveryoneBorder'] ?? markupEveryoneBorder,
      markupHereText: overrides['markupHereText'] ?? markupHereText,
      markupHereFill: overrides['markupHereFill'] ?? markupHereFill,
      markupHereBorder: overrides['markupHereBorder'] ?? markupHereBorder,
      buttonPrimaryFill: overrides['buttonPrimaryFill'] ?? buttonPrimaryFill,
      buttonPrimaryActiveFill:
          overrides['buttonPrimaryActiveFill'] ?? buttonPrimaryActiveFill,
      buttonPrimaryText: overrides['buttonPrimaryText'] ?? buttonPrimaryText,
      buttonSecondaryFill:
          overrides['buttonSecondaryFill'] ?? buttonSecondaryFill,
      buttonSecondaryActiveFill:
          overrides['buttonSecondaryActiveFill'] ?? buttonSecondaryActiveFill,
      buttonSecondaryText:
          overrides['buttonSecondaryText'] ?? buttonSecondaryText,
      buttonSecondaryActiveText:
          overrides['buttonSecondaryActiveText'] ?? buttonSecondaryActiveText,
      buttonDangerFill: overrides['buttonDangerFill'] ?? buttonDangerFill,
      buttonDangerActiveFill:
          overrides['buttonDangerActiveFill'] ?? buttonDangerActiveFill,
      buttonDangerText: overrides['buttonDangerText'] ?? buttonDangerText,
      buttonDangerOutlineBorder:
          overrides['buttonDangerOutlineBorder'] ?? buttonDangerOutlineBorder,
      buttonDangerOutlineText:
          overrides['buttonDangerOutlineText'] ?? buttonDangerOutlineText,
      buttonDangerOutlineActiveFill:
          overrides['buttonDangerOutlineActiveFill'] ??
          buttonDangerOutlineActiveFill,
      buttonGhostText: overrides['buttonGhostText'] ?? buttonGhostText,
      buttonInvertedFill: overrides['buttonInvertedFill'] ?? buttonInvertedFill,
      buttonInvertedText: overrides['buttonInvertedText'] ?? buttonInvertedText,
      buttonOutlineBorder:
          overrides['buttonOutlineBorder'] ?? buttonOutlineBorder,
      buttonOutlineText: overrides['buttonOutlineText'] ?? buttonOutlineText,
      buttonOutlineActiveFill:
          overrides['buttonOutlineActiveFill'] ?? buttonOutlineActiveFill,
      panelControlBg: overrides['panelControlBg'] ?? panelControlBg,
      panelControlBorder: overrides['panelControlBorder'] ?? panelControlBorder,
      panelControlDivider:
          overrides['panelControlDivider'] ?? panelControlDivider,
      panelControlHighlight:
          overrides['panelControlHighlight'] ?? panelControlHighlight,
      controlButtonNormalBg:
          overrides['controlButtonNormalBg'] ?? controlButtonNormalBg,
      controlButtonNormalText:
          overrides['controlButtonNormalText'] ?? controlButtonNormalText,
      controlButtonHoverBg:
          overrides['controlButtonHoverBg'] ?? controlButtonHoverBg,
      controlButtonHoverText:
          overrides['controlButtonHoverText'] ?? controlButtonHoverText,
      controlButtonActiveBg:
          overrides['controlButtonActiveBg'] ?? controlButtonActiveBg,
      controlButtonActiveText:
          overrides['controlButtonActiveText'] ?? controlButtonActiveText,
      controlButtonDangerText:
          overrides['controlButtonDangerText'] ?? controlButtonDangerText,
      controlButtonDangerHoverBg:
          overrides['controlButtonDangerHoverBg'] ?? controlButtonDangerHoverBg,
      switchTrackInactive:
          overrides['switchTrackInactive'] ?? switchTrackInactive,
      switchThumb: overrides['switchThumb'] ?? switchThumb,
      switchThumbCheckedIcon:
          overrides['switchThumbCheckedIcon'] ?? switchThumbCheckedIcon,
      switchThumbUncheckedIcon:
          overrides['switchThumbUncheckedIcon'] ?? switchThumbUncheckedIcon,
      menuDangerText: overrides['menuDangerText'] ?? menuDangerText,
      bgCode: overrides['bgCode'] ?? bgCode,
      bgCodeBlock: overrides['bgCodeBlock'] ?? bgCodeBlock,
      bgTableHeader: overrides['bgTableHeader'] ?? bgTableHeader,
      bgTableRowOdd: overrides['bgTableRowOdd'] ?? bgTableRowOdd,
      bgTableRowEven: overrides['bgTableRowEven'] ?? bgTableRowEven,
      surfaceInteractiveHoverBg:
          overrides['surfaceInteractiveHoverBg'] ?? surfaceInteractiveHoverBg,
      surfaceInteractiveSelectedBg:
          overrides['surfaceInteractiveSelectedBg'] ??
          surfaceInteractiveSelectedBg,
      surfaceInteractiveSelectedColor:
          overrides['surfaceInteractiveSelectedColor'] ??
          surfaceInteractiveSelectedColor,
      listItemSelectedBg: overrides['listItemSelectedBg'] ?? listItemSelectedBg,
      listItemSelectedBorder:
          overrides['listItemSelectedBorder'] ?? listItemSelectedBorder,
      listItemPressedBg: overrides['listItemPressedBg'] ?? listItemPressedBg,
      scrollbarThumbBg: overrides['scrollbarThumbBg'] ?? scrollbarThumbBg,
      scrollbarThumbBgHover:
          overrides['scrollbarThumbBgHover'] ?? scrollbarThumbBgHover,
      scrollbarTrackBg: overrides['scrollbarTrackBg'] ?? scrollbarTrackBg,
      textSelection: overrides['textSelection'] ?? textSelection,
      chatBackground: overrides['chatBackground'] ?? chatBackground,
      chatInputBackground:
          overrides['chatInputBackground'] ?? chatInputBackground,
      serverSidebarBackground:
          overrides['serverSidebarBackground'] ?? serverSidebarBackground,
      serverIconBackground:
          overrides['serverIconBackground'] ?? serverIconBackground,
      serverIconActive: overrides['serverIconActive'] ?? serverIconActive,
      channelSidebarBackground:
          overrides['channelSidebarBackground'] ?? channelSidebarBackground,
      memberListBackground:
          overrides['memberListBackground'] ?? memberListBackground,
      userPanelBackground:
          overrides['userPanelBackground'] ?? userPanelBackground,
      userAreaDividerColor:
          overrides['userAreaDividerColor'] ?? userAreaDividerColor,
      embedBackground: overrides['embedBackground'] ?? embedBackground,
      embedBorder: overrides['embedBorder'] ?? embedBorder,
      mentionBackground: overrides['mentionBackground'] ?? mentionBackground,
      spoilerBackground: overrides['spoilerBackground'] ?? spoilerBackground,
      spoilerOverlayHoverColor:
          overrides['spoilerOverlayHoverColor'] ?? spoilerOverlayHoverColor,
      modalScrim: overrides['modalScrim'] ?? modalScrim,
      guildBannerGradient:
          overrides['guildBannerGradient'] ?? guildBannerGradient,
      focusPrimary: overrides['focusPrimary'] ?? focusPrimary,
      interactiveActive: overrides['interactiveActive'] ?? interactiveActive,
      interactiveNormal: overrides['interactiveNormal'] ?? interactiveNormal,
      interactiveHover: overrides['interactiveHover'] ?? interactiveHover,
      interactiveMuted: overrides['interactiveMuted'] ?? interactiveMuted,
    );
  }
}
