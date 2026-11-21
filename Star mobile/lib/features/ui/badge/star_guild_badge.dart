import 'dart:async';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/instance/instance_guild_badges_provider.dart';
import 'package:star_app/core/premium/external_purchase_links_provider.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/profile/utils/profile_badge_media.dart';
import 'package:star_app/features/ui/badge/star_guild_seal_icon.dart';
import 'package:star_app/features/ui/tooltip/star_tooltip.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/external_links/external_link_handler.dart';
import 'package:star_dart/export.dart';

enum StarGuildBadgeKind { partnered, verified, discoverable }

const String _verifiedFeature = 'VERIFIED';
const String _partneredFeature = 'PARTNERED';
const String _discoverableFeature = 'DISCOVERABLE';
const double _defaultBadgeSize = 20;

class StarGuildBadge extends ConsumerWidget {
  final List<String> features;
  final List<String> badgeIds;
  final int? customBadgeLimit;
  final double size;
  final List<Shadow>? shadows;
  final Brightness? forceBrightness;
  final bool onLightSurface;

  const StarGuildBadge({
    required this.features,
    this.badgeIds = const <String>[],
    this.customBadgeLimit,
    this.size = _defaultBadgeSize,
    this.shadows,
    this.forceBrightness,
    this.onLightSurface = false,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarGuildBadgeKind? kind = _resolveKind(features);
    final List<InstanceGuildBadgeSchema> customBadges =
        resolveGuildCustomBadges(
          badgeIds: badgeIds,
          catalog: ref.watch(instanceGuildBadgesProvider),
          limit: customBadgeLimit,
        );

    final Widget? builtIn = kind == null
        ? null
        : _BuiltInGuildBadge(
            kind: kind,
            size: size,
            shadows: shadows,
            forceBrightness: forceBrightness,
            onLightSurface: onLightSurface,
          );

    if (builtIn == null && customBadges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ?builtIn,
        for (final InstanceGuildBadgeSchema badge in customBadges) ...[
          if (builtIn != null) const SizedBox(width: 4),
          _CustomGuildBadge(badge: badge, size: size),
        ],
      ],
    );
  }

  static StarGuildBadgeKind? _resolveKind(List<String> features) {
    if (features.contains(_partneredFeature)) {
      return StarGuildBadgeKind.partnered;
    }
    if (features.contains(_verifiedFeature)) {
      return StarGuildBadgeKind.verified;
    }
    if (features.contains(_discoverableFeature)) {
      return StarGuildBadgeKind.discoverable;
    }
    return null;
  }
}

class _BuiltInGuildBadge extends StatelessWidget {
  const _BuiltInGuildBadge({
    required this.kind,
    required this.size,
    this.shadows,
    this.forceBrightness,
    this.onLightSurface = false,
  });

  final StarGuildBadgeKind kind;
  final double size;
  final List<Shadow>? shadows;
  final Brightness? forceBrightness;
  final bool onLightSurface;

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        (forceBrightness ?? Theme.of(context).brightness) == Brightness.dark;
    final bool invert = onLightSurface && !isDark;
    final Color sealColor = invert
        ? context.colors.brandPrimary
        : context.colors.brandPrimaryFill;
    final Color iconColor = invert
        ? context.colors.brandPrimaryFill
        : context.colors.brandPrimary;
    return StarGuildSealIcon(
      kind: switch (kind) {
        StarGuildBadgeKind.partnered => StarGuildSealKind.partnered,
        StarGuildBadgeKind.verified => StarGuildSealKind.verified,
        StarGuildBadgeKind.discoverable => StarGuildSealKind.discoverable,
      },
      sealColor: sealColor,
      iconColor: iconColor,
      size: size,
      shadows: shadows,
    );
  }
}

class _CustomGuildBadge extends ConsumerWidget {
  const _CustomGuildBadge({required this.badge, required this.size});

  final InstanceGuildBadgeSchema badge;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String imageUrl = customBadgeImageUrl(badge.assetUrl);
    final Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.contain,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
    );

    final String? href = badge.href?.trim();
    final bool linkAllowed = ref.watch(externalPurchaseLinksAllowedProvider);
    final Widget child = href != null && href.isNotEmpty && linkAllowed
        ? GestureDetector(
            onTap: () => unawaited(handleExternalLinkTap(context, href)),
            child: image,
          )
        : image;

    final String? description = badge.description?.trim();
    final String tooltip = description == null || description.isEmpty
        ? badge.name
        : '${badge.name}\n$description';

    return StarTooltip(message: tooltip, child: child);
  }
}
