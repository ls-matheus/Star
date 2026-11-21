import 'package:star_app/features/settings/utils/oauth_authorize_url.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class ApplicationInfoSection extends StatelessWidget {
  const ApplicationInfoSection({
    required this.nameController,
    required this.nameError,
    required this.botPublic,
    required this.botRequireCodeGrant,
    required this.redirectControllers,
    required this.onBotPublicChanged,
    required this.onBotRequireCodeGrantChanged,
    required this.onAddRedirect,
    required this.onRemoveRedirect,
    super.key,
  });

  final TextEditingController nameController;
  final String? nameError;
  final bool botPublic;
  final bool botRequireCodeGrant;
  final List<TextEditingController> redirectControllers;
  final ValueChanged<bool> onBotPublicChanged;
  final ValueChanged<bool> onBotRequireCodeGrantChanged;
  final VoidCallback onAddRedirect;
  final ValueChanged<int> onRemoveRedirect;

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return StarSettingsSection(
      title: l10n.applicationsInfoTitle,
      description: l10n.applicationsInfoDescription,
      sectionId: 'applications-info',
      children: [
        StarInput(
          controller: nameController,
          label: l10n.applicationsName,
          hint: l10n.applicationsNameHint,
          maxLength: 100,
          errorText: nameError,
        ),
        StarSwitchGroup(
          children: [
            StarSwitchGroupItem(
              label: l10n.applicationsPublicBot,
              description: l10n.applicationsPublicBotDescription,
              value: botPublic,
              onChanged: onBotPublicChanged,
            ),
            StarSwitchGroupItem(
              label: l10n.applicationsRequireCodeGrant,
              description: l10n.applicationsRequireCodeGrantDescription,
              value: botRequireCodeGrant,
              onChanged: onBotRequireCodeGrantChanged,
            ),
          ],
        ),
        for (int i = 0; i < redirectControllers.length; i++)
          StarInput(
            controller: redirectControllers[i],
            label: i == 0 ? l10n.applicationsRedirectUris : null,
            hint: kExampleCallbackUrl,
            action: StarButton.secondary(
              onPressed: i == 0 ? null : () => onRemoveRedirect(i),
              semanticLabel: l10n.applicationsDeleteRedirect,
              icon: PhosphorIconsBold.x,
              size: StarButtonSize.small,
              isSquare: true,
            ),
          ),
        if (redirectControllers.length < kMaxApplicationRedirectUris)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: StarButton.primary(
              onPressed: onAddRedirect,
              label: l10n.applicationsAddRedirect,
              size: StarButtonSize.small,
              fitContent: true,
            ),
          ),
      ],
    );
  }
}
