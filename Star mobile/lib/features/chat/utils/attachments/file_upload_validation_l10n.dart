import 'package:star_app/features/chat/utils/attachments/attachment_display_utils.dart';
import 'package:star_app/features/chat/utils/attachments/file_upload_validator.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';

typedef FileUploadValidationCopy = ({String title, String body});

FileUploadValidationCopy? fileUploadValidationCopy(
  StarLocalizations l10n,
  FileUploadValidationResult result, {
  required int maxAttachments,
  required int maxFileBytes,
}) {
  if (result.isValid || result.error == null) {
    return null;
  }
  return switch (result.error!) {
    FileUploadValidationError.tooManyAttachments => (
      title: l10n.chatHeavyTitle,
      body: l10n.chatTooManyAttachmentsMessage(maxAttachments),
    ),
    FileUploadValidationError.fileTooLarge => (
      title: l10n.chatFileTooLargeTitle,
      body: l10n.chatFileTooLargeMessage(
        formatAttachmentByteSize(maxFileBytes) ?? '',
      ),
    ),
    FileUploadValidationError.multipartRequestTooLarge => (
      title: l10n.chatFileTooLargeTitle,
      body: l10n.chatAttachmentPayloadTooLarge,
    ),
    FileUploadValidationError.noFiles => null,
  };
}
