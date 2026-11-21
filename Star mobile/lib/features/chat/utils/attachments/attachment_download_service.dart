import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/api/attachment_request_auth.dart';
import 'package:star_app/core/platform/star_platform.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/features/chat/utils/attachments/attachment_display_utils.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/external_links/external_link_handler.dart';
import 'package:gal/gal.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

final Dio _attachmentDownloadDio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 2),
    followRedirects: true,
  ),
)..interceptors.add(AttachmentAuthInterceptor());

Future<void> downloadChatAttachmentMedia({
  required BuildContext context,
  required WidgetRef ref,
  required String url,
  String? filename,
}) async {
  final String trimmedUrl = url.trim();
  if (trimmedUrl.isEmpty || !context.mounted) {
    return;
  }
  if (isStarNativeMobileOs) {
    await _downloadToGallery(
      context: context,
      ref: ref,
      url: trimmedUrl,
      filename: filename,
    );
    return;
  }
  if (isStarDesktopOs) {
    await _downloadToFilePicker(
      context: context,
      ref: ref,
      url: trimmedUrl,
      filename: filename,
    );
    return;
  }
  await handleExternalLinkTap(context, trimmedUrl);
}

Future<void> saveLocalAttachmentToDeviceGallery(XFile file) async {
  if (!isStarNativeMobileOs) {
    return;
  }
  final String filePath = file.path.trim();
  if (filePath.isEmpty) {
    return;
  }
  try {
    if (!await _ensureGalleryAccess()) {
      return;
    }
    await _putLocalFileInGallery(
      filePath: filePath,
      filename: file.name.trim(),
    );
  } on GalException {
    // Optional save; ignore gallery failures.
  } on Object {
    // Optional save; ignore gallery failures.
  }
}

Future<bool> _ensureGalleryAccess() async {
  if (await Gal.hasAccess()) {
    return true;
  }
  await Gal.requestAccess();
  return await Gal.hasAccess();
}

Future<void> _putLocalFileInGallery({
  required String filePath,
  required String filename,
}) async {
  if (isVideoAttachment(filename: filename)) {
    await Gal.putVideo(filePath);
  } else {
    await Gal.putImage(filePath);
  }
}

Future<void> _downloadToGallery({
  required BuildContext context,
  required WidgetRef ref,
  required String url,
  String? filename,
}) async {
  final StarLocalizations l10n = StarLocalizations.of(context);
  try {
    if (!await _ensureGalleryAccess()) {
      _showGalleryAccessToast(ref, l10n);
      return;
    }
    final String resolvedFilename = resolveAttachmentDownloadFilename(
      url: url,
      filename: filename,
    );
    final Directory tempDir = await getTemporaryDirectory();
    final String filePath = p.join(tempDir.path, resolvedFilename);
    await _attachmentDownloadDio.download(url, filePath);
    await _putLocalFileInGallery(
      filePath: filePath,
      filename: resolvedFilename,
    );
    _showSuccessToast(ref, l10n.chatAttachmentDownloadedToast);
  } on GalException {
    _showFailureToast(ref, l10n.chatAttachmentDownloadFailedToast);
  } on Object {
    _showFailureToast(ref, l10n.chatAttachmentDownloadFailedToast);
  }
}

Future<void> _downloadToFilePicker({
  required BuildContext context,
  required WidgetRef ref,
  required String url,
  String? filename,
}) async {
  final StarLocalizations l10n = StarLocalizations.of(context);
  File? destination;
  try {
    final String resolvedFilename = resolveAttachmentDownloadFilename(
      url: url,
      filename: filename,
    );
    final Uri? uri = await FilePicker.saveFile(
      dialogTitle: l10n.chatAttachmentDownload,
      fileName: resolvedFilename,
      bytes: Uint8List(0),
    );
    if (uri == null) {
      return;
    }
    destination = File(uri.toFilePath());
    await _attachmentDownloadDio.download(url, destination.path);
    _showSuccessToast(ref, l10n.chatAttachmentDownloadedToast);
  } on Object {
    if (destination != null) {
      await _deletePartialDownload(destination);
    }
    _showFailureToast(ref, l10n.chatAttachmentDownloadFailedToast);
  }
}

Future<void> _deletePartialDownload(File file) async {
  try {
    if (file.existsSync()) {
      await file.delete();
    }
  } on Object {
    return;
  }
}

String resolveAttachmentDownloadFilename({
  required String url,
  String? filename,
}) {
  final String trimmedFilename = filename?.trim() ?? '';
  if (trimmedFilename.isNotEmpty) {
    return trimmedFilename;
  }
  final Uri? uri = Uri.tryParse(url);
  if (uri != null) {
    final String fromPath = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : '';
    if (fromPath.isNotEmpty && fromPath.contains('.')) {
      return fromPath;
    }
  }
  return 'attachment';
}

void _showSuccessToast(WidgetRef ref, String message) {
  ref
      .read(toastProvider.notifier)
      .show(StarToast(message: message, variant: StarToastVariant.success));
}

void _showGalleryAccessToast(WidgetRef ref, StarLocalizations l10n) {
  final String productName = ref
      .read(instanceRuntimeConfigProvider)
      .productName;
  ref
      .read(toastProvider.notifier)
      .show(
        StarToast(
          message: l10n.chatAttachmentDownloadPhotosAccessToast(productName),
          variant: StarToastVariant.danger,
          duration: const Duration(seconds: 6),
          action: StarToastAction(
            label: l10n.systemPermissionSettingsOpenSettings,
            onPressed: () => unawaited(openAppSettings()),
          ),
        ),
      );
}

void _showFailureToast(WidgetRef ref, String message) {
  ref
      .read(toastProvider.notifier)
      .show(StarToast(message: message, variant: StarToastVariant.danger));
}
