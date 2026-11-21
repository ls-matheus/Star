import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/constants/contact_emails.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/settings/utils/messaging_paused_help_email.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/input/star_input.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/external_links/external_link_handler.dart';
import 'package:star_app/shared/utils/clipboard_utils.dart';
import 'package:star_app/shared/utils/user_tag.dart';

class MessagingPausedHelpSheet extends ConsumerStatefulWidget {
  const MessagingPausedHelpSheet({super.key});

  static Future<void> show(BuildContext context) {
    return StarBottomSheet.show<void>(
      context,
      title: StarLocalizations.of(context).messagingPausedTextDidNotGoThrough,
      useRootNavigator: true,
      builder: (_, _) => const MessagingPausedHelpSheet(),
    );
  }

  @override
  ConsumerState<MessagingPausedHelpSheet> createState() =>
      _MessagingPausedHelpSheetState();
}

class _MessagingPausedHelpSheetState
    extends ConsumerState<MessagingPausedHelpSheet> {
  final TextEditingController _countryController = TextEditingController();

  @override
  void dispose() {
    _countryController.dispose();
    super.dispose();
  }

  MessagingPausedHelpEmail _email() {
    final UserSettingsViewState settings = ref.read(
      userSettingsViewModelProvider,
    );
    return buildMessagingPausedHelpEmail(
      l10n: StarLocalizations.of(context),
      accountId: settings.userId,
      userTag: formatUserTag(
        settings.username,
        settings.discriminator,
        uniqueUsernames: ref.read(uniqueUsernamesProvider),
      ),
      createdAt: settings.resolvedMemberSince,
      country: _countryController.text,
    );
  }

  Future<void> _copyDetails() {
    return copyToClipboard(
      context: context,
      value: '${ContactEmails.support}\n\n${_email().body}',
    );
  }

  Future<void> _emailSupport() {
    return handleExternalLinkTap(context, _email().mailto, skipWarning: true);
  }

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final layout = context.layout;
    return SingleChildScrollView(
      padding: settingsSheetScrollPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            l10n.messagingPausedHelpBody(ContactEmails.support),
            style: context.textStyles.bodySmall.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          SizedBox(height: layout.s4),
          StarInput(
            controller: _countryController,
            label: l10n.messagingPausedHelpCountryLabel,
            maxLength: 100,
            autofillHints: const <String>[AutofillHints.countryName],
            textInputAction: TextInputAction.done,
          ),
          SizedBox(height: layout.s4),
          Row(
            children: <Widget>[
              Expanded(
                child: StarButton.secondary(
                  label: l10n.messagingPausedHelpCopyDetails,
                  onPressedAsync: _copyDetails,
                  fitContent: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StarButton.primary(
                  label: l10n.messagingPausedHelpEmailSupport,
                  onPressedAsync: _emailSupport,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
