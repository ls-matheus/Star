import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/deep_links/user_settings_deep_link.dart';
import 'package:star_app/features/settings/domain/user_settings_section.dart';
import 'package:star_app/features/settings/utils/user_settings/open_user_settings_deep_link.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/features/voice/presentation/widgets/voice_call_desktop_hud/voice_call_hud_style.dart';
import 'package:star_app/features/voice/providers/voice_call_overlay_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

typedef VoiceCallHudMenuBuilder = Widget Function(VoidCallback close);

Future<void> showVoiceCallHudMenu(
  BuildContext anchor,
  WidgetRef ref, {
  required VoiceCallHudMenuBuilder builder,
}) async {
  final RenderObject? renderObject = anchor.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) {
    return;
  }
  final Rect anchorRect =
      renderObject.localToGlobal(Offset.zero) & renderObject.size;
  final VoiceCallOverlay overlay = ref.read(voiceCallOverlayProvider.notifier)
    ..setMenuPinned(value: true);
  try {
    await pushStarDesktopMenu<void>(
      anchor,
      position: anchorRect.topLeft,
      anchorRect: anchorRect,
      placement: StarDesktopPlacement.aboveStart,
      builder: (BuildContext menuContext, VoidCallback close) {
        return StarDesktopMenuPanel(
          width: kVoiceCallHudMenuWidth,
          child: SingleChildScrollView(child: builder(close)),
        );
      },
    );
  } finally {
    overlay.setMenuPinned(value: false);
  }
}

Future<void> openVoiceCallHudAudioVideoSettings(
  BuildContext context,
  WidgetRef ref,
) async {
  if (!context.mounted) {
    return;
  }
  await openUserSettingsDeepLink(
    context,
    ref,
    const UserSettingsDeepLinkTarget(
      section: UserSettingsSection.audioAndVideo,
    ),
  );
}

class VoiceCallHudMenuSettingsItem extends StatelessWidget {
  const VoiceCallHudMenuSettingsItem({
    required this.onClose,
    required this.onOpenSettings,
    super.key,
  });

  final VoidCallback onClose;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return StarMenuItem(
      label: StarLocalizations.of(context).userSettingsNavAudioAndVideo,
      icon: PhosphorIconsFill.gear,
      onPressed: () {
        onClose();
        onOpenSettings();
      },
    );
  }
}
