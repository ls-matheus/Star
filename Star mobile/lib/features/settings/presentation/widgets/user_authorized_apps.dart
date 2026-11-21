import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/media/star_media_url.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/settings/providers/view_models/authorized_apps_view_model.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/utils/user_date_formatting.dart';
import 'package:star_dart/export.dart';

class UserAuthorizedApps extends ConsumerStatefulWidget {
  const UserAuthorizedApps({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  ConsumerState<UserAuthorizedApps> createState() => _UserAuthorizedAppsState();
}

class _UserAuthorizedAppsState extends ConsumerState<UserAuthorizedApps> {
  final _expandedIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authorizedAppsViewModelProvider);
    final colors = context.colors;
    final layout = context.layout;
    final l10n = StarLocalizations.of(context);

    final Widget body;
    if (state.isLoading) {
      body = const Center(child: StarLoadingSpinner());
    } else if (state.error != null) {
      body = Padding(
        padding: EdgeInsets.symmetric(vertical: layout.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIconsFill.networkSlash,
              size: 48,
              color: colors.textPrimaryMuted,
            ),
            SizedBox(height: layout.s3),
            Text(
              l10n.authorizedAppsLoadError,
              style: context.textStyles.bodySmall.copyWith(
                color: colors.textPrimaryMuted,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: layout.s4),
            StarButton.primary(
              label: l10n.retry,
              onPressedAsync: ref
                  .read(authorizedAppsViewModelProvider.notifier)
                  .load,
            ),
          ],
        ),
      );
    } else if (state.authorizations.isEmpty) {
      body = Padding(
        padding: EdgeInsets.symmetric(vertical: layout.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIconsFill.appWindow,
              size: 48,
              color: colors.textPrimaryMuted,
            ),
            SizedBox(height: layout.s3),
            Text(
              l10n.authorizedAppsEmptyTitle,
              style: context.textStyles.heading.copyWith(
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: layout.s1),
            Text(
              l10n.authorizedAppsEmptyDescription,
              style: context.textStyles.bodySmall.copyWith(
                color: colors.textPrimaryMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      body = Padding(
        padding: EdgeInsets.symmetric(vertical: layout.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StarSettingsSection(
              title: l10n.authorizedAppsTitle,
              description: l10n.authorizedAppsDescription(
                ref.watch(
                  instanceRuntimeConfigProvider.select(
                    (config) => config.productName,
                  ),
                ),
              ),
              isFirst: true,
              children: [
                for (final authorization in state.authorizations)
                  _AuthorizedAppCard(
                    authorization: authorization,
                    isExpanded: _expandedIds.contains(
                      authorization.application.id,
                    ),
                    onToggle: () =>
                        _toggleExpanded(authorization.application.id),
                    onRevoke: () => _handleRevoke(authorization),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: settingsScrollPadding(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 1),
        child: body,
      ),
    );
  }

  void _toggleExpanded(String appId) {
    setState(() {
      if (_expandedIds.contains(appId)) {
        _expandedIds.remove(appId);
      } else {
        _expandedIds.add(appId);
      }
    });
  }

  Future<void> _handleRevoke(OAuth2AuthorizationResponse authorization) async {
    final appName = authorization.application.name;
    final l10n = StarLocalizations.of(context);
    final layout = context.layout;
    final colors = context.colors;
    final notifier = ref.read(authorizedAppsViewModelProvider.notifier);

    await StarBottomSheet.show<void>(
      context,
      title: l10n.authorizedAppsRevokeTitle,
      useRootNavigator: true,
      builder: (sheetContext, close) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: layout.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.authorizedAppsRevokeDescription(appName),
                style: sheetContext.textStyles.bodySmall.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: layout.s4),
              StarButton.dangerPrimary(
                label: l10n.authorizedAppsRevoke,
                onPressedAsync: () async {
                  await notifier.deauthorize(authorization.application.id);
                  if (sheetContext.mounted) {
                    close();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AuthorizedAppCard extends StatelessWidget {
  const _AuthorizedAppCard({
    required this.authorization,
    required this.isExpanded,
    required this.onToggle,
    required this.onRevoke,
  });

  final OAuth2AuthorizationResponse authorization;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onRevoke;

  static const double _iconSize = 32;
  static const double _iconPlaceholderSize = 18;

  Widget _buildAppIcon(
    BuildContext context,
    StarColorTheme colors,
    String? iconUrl,
  ) {
    final placeholder = Center(
      child: PhosphorIcon(
        PhosphorIconsFill.appWindow,
        size: _iconPlaceholderSize,
        color: colors.textTertiary,
      ),
    );

    return Container(
      width: _iconSize,
      height: _iconSize,
      decoration: BoxDecoration(
        color: colors.backgroundTertiary,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: iconUrl != null
          ? CachedNetworkImage(
              imageUrl: iconUrl,
              width: _iconSize,
              height: _iconSize,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
            )
          : placeholder,
    );
  }

  String _formatDate(String localeName) {
    final dt = DateTime.tryParse(authorization.authorizedAt);
    if (dt == null) {
      return authorization.authorizedAt;
    }
    return formatUserMediumDate(dt.toLocal(), localeName);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundTertiary,
        border: Border.all(color: colors.borderColor),
        borderRadius: layout.radiusLg,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, colors, layout),
          if (isExpanded) _buildDetails(context, colors, layout),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    StarColorTheme colors,
    StarLayoutTheme layout,
  ) {
    final iconUrl = StarMediaUrl.userAvatar(
      userId: authorization.application.id,
      hash: authorization.application.icon,
    );
    final l10n = StarLocalizations.of(context);

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: layout.s3,
          vertical: layout.s3,
        ),
        child: Row(
          children: [
            _buildAppIcon(context, colors, iconUrl),
            SizedBox(width: layout.s2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authorization.application.name,
                    style: context.textStyles.bodySmall.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: layout.s1 / 2),
                  Text(
                    l10n.authorizedAppsAuthorizedOn(
                      _formatDate(l10n.localeName),
                    ),
                    style: context.textStyles.bodySmall.copyWith(
                      color: colors.textPrimaryMuted,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: layout.s2),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: context.motion.panel,
              child: PhosphorIcon(
                PhosphorIconsBold.caretDown,
                size: 20,
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails(
    BuildContext context,
    StarColorTheme colors,
    StarLayoutTheme layout,
  ) {
    final l10n = StarLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, thickness: 1, color: colors.borderColor),
        Padding(
          padding: EdgeInsets.all(layout.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StarSubsectionLabel(l10n.authorizedAppsPermissionsGranted),
              SizedBox(height: layout.s2),
              for (int i = 0; i < authorization.scopes.length; i++) ...[
                _buildScopeTag(
                  context,
                  colors,
                  layout,
                  authorization.scopes[i],
                ),
                if (i < authorization.scopes.length - 1)
                  SizedBox(height: layout.s2),
              ],
              SizedBox(height: layout.s3),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: StarButton.dangerPrimary(
                  label: l10n.authorizedAppsRevoke,
                  size: StarButtonSize.compact,
                  onPressed: onRevoke,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScopeTag(
    BuildContext context,
    StarColorTheme colors,
    StarLayoutTheme layout,
    String scope,
  ) {
    final description = _scopeDescription(
      StarLocalizations.of(context),
      scope,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(layout.s2),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        border: Border.all(color: colors.borderColor),
        borderRadius: layout.radiusMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            scope,
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
          if (description != null) ...[
            SizedBox(height: layout.s1 / 2),
            Text(
              description,
              style: context.textStyles.bodySmall.copyWith(
                color: colors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String? _scopeDescription(StarLocalizations l10n, String scope) {
    switch (scope) {
      case 'identify':
        return l10n.authorizedAppsScopeIdentify;
      case 'email':
        return l10n.authorizedAppsScopeEmail;
      case 'guilds':
        return l10n.authorizedAppsScopeGuilds;
      case 'connections':
        return l10n.authorizedAppsScopeConnections;
      case 'bot':
        return l10n.authorizedAppsScopeBot;
      case 'admin':
        return l10n.authorizedAppsScopeAdmin;
      default:
        return null;
    }
  }
}
