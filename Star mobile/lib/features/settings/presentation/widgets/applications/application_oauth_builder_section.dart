import 'package:star_app/core/permissions/permission.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/domain/guild/roles/guild_role_permission_spec.dart';
import 'package:star_app/features/settings/presentation/widgets/applications/application_read_only_input.dart';
import 'package:star_app/features/settings/utils/oauth_authorize_url.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class ApplicationOauthBuilderSection extends StatelessWidget {
  const ApplicationOauthBuilderSection({
    required this.selectedScopes,
    required this.selectedPermissions,
    required this.redirectOptions,
    required this.selectedRedirectUri,
    required this.botRequireCodeGrant,
    required this.authorizeUrl,
    required this.onToggleScope,
    required this.onTogglePermission,
    required this.onRedirectChanged,
    required this.onCopyUrl,
    this.isFirst = false,
    super.key,
  });

  final Set<String> selectedScopes;
  final Set<Permission> selectedPermissions;
  final List<String> redirectOptions;
  final String? selectedRedirectUri;
  final bool botRequireCodeGrant;
  final String authorizeUrl;
  final ValueChanged<String> onToggleScope;
  final ValueChanged<Permission> onTogglePermission;
  final ValueChanged<String> onRedirectChanged;
  final VoidCallback onCopyUrl;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final layout = context.layout;
    final List<GuildPermissionEntry> permissions = generateGuildPermissionSpec(
      l10n,
    ).expand((category) => category.permissions).toList();
    final List<String> scopes = selectedScopes.toList();
    final bool isBotOnly = scopes.length == 1 && scopes.first == 'bot';
    final bool redirectRequired =
        scopes.isNotEmpty && (!isBotOnly || botRequireCodeGrant);
    final String? redirectError;
    if (redirectRequired &&
        (selectedRedirectUri == null || selectedRedirectUri!.isEmpty)) {
      redirectError = isBotOnly && botRequireCodeGrant
          ? l10n.applicationsRedirectRequiredCodeGrant
          : l10n.applicationsRedirectRequiredScopes;
    } else {
      redirectError = null;
    }

    return StarSettingsSection(
      title: l10n.applicationsOauthBuilderTitle,
      description: l10n.applicationsOauthBuilderDescription,
      isFirst: isFirst,
      sectionId: 'applications-oauth-builder',
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StarFieldLabel(l10n.applicationsScopes),
            SizedBox(height: layout.s2),
            Wrap(
              spacing: layout.s3,
              runSpacing: layout.s2,
              children: [
                for (final String scope in kOAuth2Scopes)
                  StarCheckbox(
                    value: selectedScopes.contains(scope),
                    onChanged: (_) => onToggleScope(scope),
                    label: scope,
                  ),
              ],
            ),
          ],
        ),
        StarSelect<String>(
          label: l10n.applicationsRedirectUri,
          hint: l10n.applicationsSelectRedirectUri,
          value: selectedRedirectUri,
          errorText: redirectError,
          enableSearch: false,
          items: [
            for (final String uri in redirectOptions)
              StarSelectItem<String>(value: uri, label: uri),
          ],
          onChanged: onRedirectChanged,
        ),
        if (selectedScopes.contains('bot'))
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StarFieldLabel(l10n.applicationsBotPermissions),
              SizedBox(height: layout.s2),
              Wrap(
                spacing: layout.s3,
                runSpacing: layout.s2,
                children: [
                  for (final GuildPermissionEntry perm in permissions)
                    StarCheckbox(
                      value: selectedPermissions.contains(perm.flag),
                      onChanged: (_) => onTogglePermission(perm.flag),
                      label: perm.title,
                    ),
                ],
              ),
            ],
          ),
        ApplicationReadOnlyInput(
          text: authorizeUrl,
          label: l10n.applicationsAuthorizeUrl,
          hint: l10n.applicationsAuthorizeUrlPlaceholder,
          trailing: StarButton.primary(
            onPressed: authorizeUrl.isEmpty ? null : onCopyUrl,
            semanticLabel: l10n.applicationsCopyAuthorizeUrl,
            icon: PhosphorIconsBold.copy,
            size: StarButtonSize.compact,
            isSquare: true,
          ),
        ),
      ],
    );
  }
}
