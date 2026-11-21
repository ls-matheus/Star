import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/forum/presentation/sheets/forum_post_composer_sheet.dart';
import 'package:star_app/features/ui/button/star_circle_fab.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class ForumNewPostFab extends ConsumerWidget {
  const ForumNewPostFab({required this.forum, super.key});

  final Channel forum;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return StarCircleFab(
      icon: PhosphorIconsBold.plus,
      semanticLabel: l10n.forumNewPost,
      onTap: () =>
          unawaited(showForumPostComposerSheet(context, ref, forum: forum)),
    );
  }
}
