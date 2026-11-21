import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/media/star_media_url.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/dm/domain/dm_conversation.dart';
import 'package:star_app/features/dm/providers/dm_providers.dart';
import 'package:star_app/features/dm/utils/group_dm_display_name.dart';
import 'package:star_app/features/settings/presentation/widgets/image_crop_sheet.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/utils/api_error_presentation.dart';
import 'package:star_app/shared/utils/image_utils.dart';

class EditGroupDmContent extends ConsumerStatefulWidget {
  const EditGroupDmContent({
    required this.dm,
    required this.onSaved,
    this.scrollController,
    super.key,
  });

  final DmConversation dm;
  final VoidCallback onSaved;
  final ScrollController? scrollController;

  @override
  ConsumerState<EditGroupDmContent> createState() => _EditGroupDmContentState();
}

class _EditGroupDmContentState extends ConsumerState<EditGroupDmContent> {
  static const int _maxNameLength = 100;
  static const double _iconPreviewSize = 80;
  static const String _maxIconSizeLabel = '10 MB';

  late final TextEditingController _nameController;
  String? _pendingIconUri;
  bool _iconCleared = false;
  bool _isSaving = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.dm.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _hasIcon =>
      (_pendingIconUri != null || widget.dm.icon != null) && !_iconCleared;

  Future<void> _showIconErrorModal({
    required String title,
    required String message,
  }) {
    return showErrorDialog(context, title: title, body: message);
  }

  Future<void> _handleUploadIcon() async {
    final StarLocalizations l10n = StarLocalizations.of(context);
    try {
      final ({Uint8List bytes, String name})? picked =
          await ImageUtils.pickImage();
      if (picked == null || !mounted) {
        return;
      }
      if (ImageUtils.isOverSizeLimit(picked.bytes)) {
        await _showIconErrorModal(
          title: l10n.groupDmIconFileTooLargeTitle,
          message: l10n.groupDmIconFileTooLargeBody(_maxIconSizeLabel),
        );
        return;
      }
      if (ImageUtils.detectMimeType(picked.bytes) ==
          'application/octet-stream') {
        await _showIconErrorModal(
          title: l10n.groupDmUnsupportedIconFormat,
          message: l10n.groupDmUnsupportedIconFormatBody,
        );
        return;
      }
      final AnimationCheckResult animCheck = ImageUtils.checkAnimated(
        picked.bytes,
      );
      if (animCheck.isAnimated) {
        await _showIconErrorModal(
          title: l10n.groupDmAnimatedIconNotSupportedTitle,
          message: l10n.groupDmAnimatedIconNotSupported,
        );
        return;
      }
      if (!mounted) {
        return;
      }
      final Uint8List? croppedBytes = await showImageCropSheet(
        context,
        imageBytes: picked.bytes,
        aspectRatio: 1,
        title: l10n.groupDmChangeIcon,
        maskShape: CropMaskShape.circle,
      );
      if (croppedBytes == null || !mounted) {
        return;
      }
      setState(() {
        _pendingIconUri = ImageUtils.toDataUri(croppedBytes);
        _iconCleared = false;
      });
    } on Object {
      if (!mounted) {
        return;
      }
      await _showIconErrorModal(
        title: l10n.groupDmInvalidImage,
        message: l10n.groupDmInvalidImageBody,
      );
    }
  }

  void _handleRemoveIcon() {
    setState(() {
      _pendingIconUri = null;
      _iconCleared = true;
    });
  }

  Future<void> _handleSave() async {
    if (_isSaving) {
      return;
    }
    final StarLocalizations l10n = StarLocalizations.of(context);
    final String trimmedName = _nameController.text.trim();
    if (trimmedName.length > _maxNameLength) {
      setState(() => _nameError = l10n.groupDmGroupNameMaxLength);
      return;
    }
    setState(() {
      _nameError = null;
      _isSaving = true;
    });
    try {
      await ref
          .read(dmRepositoryProvider)
          .updateGroupDm(
            channelId: widget.dm.id,
            name: trimmedName.isEmpty ? null : trimmedName,
            icon: _pendingIconUri,
            removeIcon: _iconCleared,
          );
      if (!mounted) {
        return;
      }
      ref
          .read(toastProvider.notifier)
          .show(StarToast(message: l10n.groupDmUpdated));
      widget.onSaved();
    } on Object {
      if (!mounted) {
        return;
      }
      ref
          .read(toastProvider.notifier)
          .show(
            StarToast(
              message: l10n.groupDmUpdateFailed,
              variant: StarToastVariant.danger,
            ),
          );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _resolveNamePlaceholder(StarLocalizations l10n) {
    final String? currentUserId = ref.read(currentUserIdProvider);
    final String displayName = resolveGroupDmDisplayName(
      dm: widget.dm,
      l10n: l10n,
      currentUserId: currentUserId,
    );
    if (displayName.isNotEmpty) {
      return displayName;
    }
    return l10n.groupDmMyGroup;
  }

  Widget _buildForm(StarLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          l10n.groupDmGroupIcon,
          style: context.textStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: context.layout.s2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildIconPreview(),
            SizedBox(width: context.layout.s4),
            Expanded(
              child: Wrap(
                spacing: context.layout.s2,
                runSpacing: context.layout.s2,
                children: <Widget>[
                  StarButton.primary(
                    onPressed: _isSaving
                        ? null
                        : () => unawaited(_handleUploadIcon()),
                    label: _hasIcon
                        ? l10n.groupDmChangeIcon
                        : l10n.groupDmUploadIcon,
                    size: StarButtonSize.small,
                    fitContent: true,
                  ),
                  if (_hasIcon)
                    StarButton.secondary(
                      onPressed: _isSaving ? null : _handleRemoveIcon,
                      label: l10n.groupDmRemoveIcon,
                      size: StarButtonSize.small,
                      fitContent: true,
                    ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: context.layout.s3),
        StarHintText(l10n.avatarDescription),
        SizedBox(height: context.layout.s4),
        StarInput(
          controller: _nameController,
          label: l10n.groupDmGroupName,
          hint: _resolveNamePlaceholder(l10n),
          errorText: _nameError,
          maxLength: _maxNameLength,
          showCounter: true,
          counterMax: _maxNameLength,
          enabled: !_isSaving,
        ),
      ],
    );
  }

  Widget _buildSaveButton(StarLocalizations l10n) {
    return StarButton.primary(
      label: l10n.save,
      isLoading: _isSaving,
      onPressed: _isSaving ? null : () => unawaited(_handleSave()),
    );
  }

  Widget _buildIconPreview() {
    if (_pendingIconUri != null) {
      return _buildCirclePreview(child: _buildDataUriImage(_pendingIconUri!));
    }
    final String? iconHash = widget.dm.icon;
    if (!_iconCleared && iconHash != null) {
      final String? iconUrl = StarMediaUrl.guildIcon(
        guildId: widget.dm.id,
        hash: iconHash,
      );
      if (iconUrl != null) {
        return _buildCirclePreview(
          child: Image.network(
            iconUrl,
            width: _iconPreviewSize,
            height: _iconPreviewSize,
            fit: BoxFit.cover,
          ),
        );
      }
    }
    return _buildIconPlaceholder();
  }

  Widget _buildIconPlaceholder() {
    return SizedBox(
      width: _iconPreviewSize,
      height: _iconPreviewSize,
      child: CustomPaint(
        painter: DashedBorderPainter(
          shape: DashedBorderShape.circle,
          color: context.colors.textTertiary,
          strokeWidth: 4,
        ),
        child: Center(
          child: PhosphorIcon(
            PhosphorIconsBold.plus,
            size: 32,
            color: context.colors.textTertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildCirclePreview({required Widget child}) {
    return Container(
      width: _iconPreviewSize,
      height: _iconPreviewSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: child,
    );
  }

  Widget _buildDataUriImage(String dataUri) {
    final Uint8List? bytes = ImageUtils.decodeDataUri(dataUri);
    if (bytes == null) {
      return const SizedBox.square(dimension: _iconPreviewSize);
    }
    return Image.memory(
      bytes,
      width: _iconPreviewSize,
      height: _iconPreviewSize,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final Widget form = _buildForm(l10n);
    final Widget saveButton = _buildSaveButton(l10n);
    final ScrollController? scrollController = widget.scrollController;
    if (scrollController != null) {
      return Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: StarBottomSheet.scrollViewPadding(
                context,
                padding: EdgeInsets.symmetric(horizontal: context.layout.s4),
              ),
              child: form,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.layout.s4,
              context.layout.s3,
              context.layout.s4,
              StarBottomSheet.scrollBottomPaddingOf(context),
            ),
            child: saveButton,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        form,
        SizedBox(height: context.layout.s4),
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: context.colors.backgroundHeaderSecondary),
            ),
          ),
          padding: EdgeInsets.only(top: context.layout.s4),
          child: saveButton,
        ),
      ],
    );
  }
}
