import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/chat/presentation/widgets/pickers/expression_picker.dart';
import 'package:star_app/features/forum/data/forum_repository.dart';
import 'package:star_app/features/forum/domain/forum_channel.dart';
import 'package:star_app/features/forum/presentation/widgets/forum_tag_chip.dart';
import 'package:star_app/features/threads/utils/thread_actions.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/emoji_picker/star_emoji_picker_sheet.dart';
import 'package:star_app/features/ui/emoji_picker/star_selected_emoji.dart';
import 'package:star_app/features/ui/input/star_input.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toggle_switch/star_toggle_switch.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart' hide ChannelType;

Future<void> showForumTagEditSheet(
  BuildContext context, {
  required Channel forum,
  ForumTagResponse? tag,
}) => StarBottomSheet.show<void>(
  context,
  title: tag == null
      ? StarLocalizations.of(context).forumCreateTag
      : StarLocalizations.of(context).forumEditTag,
  builder: (BuildContext sheetContext, VoidCallback close) =>
      _ForumTagEditor(forum: forum, tag: tag, close: close),
);

class _ForumTagEditor extends ConsumerStatefulWidget {
  const _ForumTagEditor({required this.forum, required this.close, this.tag});

  final Channel forum;
  final ForumTagResponse? tag;
  final VoidCallback close;

  @override
  ConsumerState<_ForumTagEditor> createState() => _ForumTagEditorState();
}

class _ForumTagEditorState extends ConsumerState<_ForumTagEditor> {
  late final TextEditingController _name = TextEditingController(
    text: widget.tag?.name ?? '',
  );
  late bool _moderated = widget.tag?.moderated ?? false;
  late String? _emojiId = widget.tag?.emojiId;
  late String? _emojiName = widget.tag?.emojiName;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function(ForumRepository repo) action) async {
    final StarLocalizations l10n = StarLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await action(ref.read(forumRepositoryProvider));
    } on Object catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        showThreadToast(
          ref,
          threadErrorText(l10n, error),
          variant: StarToastVariant.danger,
        );
      }
      return;
    }
    if (mounted) {
      widget.close();
    }
  }

  ForumTagDraft get _draft => ForumTagDraft(
    name: _name.text.trim(),
    moderated: _moderated,
    emojiId: _emojiId,
    emojiName: _emojiName,
  );

  Future<void> _save() {
    final ForumTagResponse? tag = widget.tag;
    return _run(
      (ForumRepository repo) => tag == null
          ? repo.createTag(
              guildId: widget.forum.guildId,
              forumId: widget.forum.id,
              tag: _draft,
            )
          : repo.updateTag(
              guildId: widget.forum.guildId,
              forumId: widget.forum.id,
              tagId: tag.id,
              tag: _draft,
            ),
    );
  }

  Future<void> _delete(String tagId) => _run(
    (ForumRepository repo) => repo.deleteTag(
      guildId: widget.forum.guildId,
      forumId: widget.forum.id,
      tagId: tagId,
    ),
  );

  void _pickEmoji() {
    unawaited(
      StarEmojiPickerSheet.show(
        context,
        title: StarLocalizations.of(context).forumTagEmoji,
        visibleTabs: const <ExpressionPickerTab>[ExpressionPickerTab.emojis],
        onEmojiSelected: (StarSelectedEmoji emoji) => setState(() {
          _emojiId = emoji.emojiId;
          _emojiName = emoji.isCustom ? emoji.name : emoji.surrogates;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final layout = context.layout;
    final ForumTagResponse? tag = widget.tag;
    final bool hasEmoji = _emojiId != null || (_emojiName ?? '').isNotEmpty;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: layout.s4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          StarInput(
            label: l10n.forumTagName,
            hint: l10n.forumTagName,
            controller: _name,
            maxLength: forumTagNameMaxLength,
            autofocus: tag == null,
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: layout.s3),
          Row(
            children: <Widget>[
              if (hasEmoji) ...<Widget>[
                ForumEmoji(emojiId: _emojiId, emojiName: _emojiName, size: 24),
                SizedBox(width: layout.s3),
              ],
              StarButton.secondary(
                onPressed: _busy ? null : _pickEmoji,
                label: l10n.forumTagEmoji,
                fitContent: true,
              ),
              if (hasEmoji) ...<Widget>[
                SizedBox(width: layout.s2),
                StarButton.ghost(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _emojiId = null;
                          _emojiName = null;
                        }),
                  label: l10n.forumTagRemoveEmoji,
                  fitContent: true,
                ),
              ],
            ],
          ),
          SizedBox(height: layout.s3),
          StarToggleSwitch(
            value: _moderated,
            label: l10n.forumTagModerated,
            description: l10n.forumTagModeratedDescription,
            onChanged: (bool value) => setState(() => _moderated = value),
          ),
          SizedBox(height: layout.s4),
          StarButton.primary(
            onPressed: _busy || _name.text.trim().isEmpty
                ? null
                : () => unawaited(_save()),
            isLoading: _busy,
            label: tag == null ? l10n.forumCreateTag : l10n.forumSaveTag,
          ),
          if (tag != null) ...<Widget>[
            SizedBox(height: layout.s2),
            StarButton.dangerSecondary(
              onPressed: _busy ? null : () => unawaited(_delete(tag.id)),
              label: l10n.forumDeleteTag,
            ),
          ],
        ],
      ),
    );
  }
}
