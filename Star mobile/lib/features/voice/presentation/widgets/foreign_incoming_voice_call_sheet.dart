import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/voice/presentation/widgets/incoming_voice_call_sheet.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

Future<String?> showForeignIncomingVoiceCallSheet(
  BuildContext context, {
  required String callerName,
  String? avatarUrl,
}) {
  final StarLocalizations l10n = StarLocalizations.of(context);
  final String title = callerName.trim().isEmpty
      ? l10n.incomingVoiceCallTitle
      : callerName.trim();
  return StarBottomSheet.showScrollable<String>(
    context,
    useRootNavigator: true,
    title: title,
    isDismissible: false,
    initialChildSize: StarBottomSheet.scrollableSheetHalfSize,
    minChildSize: 0.28,
    builder: (BuildContext sheetContext, ScrollController scrollController, _) {
      return _ForeignIncomingCallSheet(
        scrollController: scrollController,
        callerName: title,
        avatarUrl: avatarUrl,
        onResult: (String result) {
          final NavigatorState navigator = Navigator.of(
            sheetContext,
            rootNavigator: true,
          );
          if (navigator.canPop()) {
            navigator.pop<String>(result);
          }
        },
      );
    },
  );
}

class _ForeignIncomingCallSheet extends StatelessWidget {
  const _ForeignIncomingCallSheet({
    required this.scrollController,
    required this.callerName,
    required this.onResult,
    this.avatarUrl,
  });

  final ScrollController scrollController;
  final String callerName;
  final String? avatarUrl;
  final ValueChanged<String> onResult;

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final layout = context.layout;
    return SingleChildScrollView(
      controller: scrollController,
      padding: StarBottomSheet.scrollViewPadding(
        context,
        padding: EdgeInsets.symmetric(horizontal: layout.s4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              PhosphorIcon(
                PhosphorIconsBold.phoneIncoming,
                size: 18,
                color: context.colors.textSecondary,
              ),
              SizedBox(width: layout.s2),
              Text(
                l10n.incomingVoiceCallLabel,
                style: context.textStyles.categoryName.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: layout.s4),
          Center(child: _CallerAvatar(avatarUrl: avatarUrl)),
          SizedBox(height: layout.s3),
          Text(
            callerName,
            textAlign: TextAlign.center,
            style: context.textStyles.channelName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: layout.s4),
          FilledButton.icon(
            onPressed: () => onResult(kIncomingVoiceResultAccept),
            icon: PhosphorIcon(
              PhosphorIconsFill.phone,
              size: 18,
              color: context.colors.textPrimary,
            ),
            label: Text(l10n.incomingVoiceCallAccept),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          SizedBox(height: layout.s3),
          FilledButton.icon(
            onPressed: () => onResult(kIncomingVoiceResultReject),
            icon: PhosphorIcon(
              PhosphorIconsBold.x,
              size: 18,
              color: context.colors.buttonDangerText,
            ),
            label: Text(l10n.incomingVoiceCallDecline),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: context.colors.buttonDangerFill,
              foregroundColor: context.colors.buttonDangerText,
            ),
          ),
          SizedBox(height: layout.s3),
          OutlinedButton(
            onPressed: () => onResult(kIncomingVoiceResultIgnore),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(l10n.incomingVoiceCallIgnore),
          ),
        ],
      ),
    );
  }
}

class _CallerAvatar extends StatelessWidget {
  const _CallerAvatar({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    const double size = 80;
    final String? url = avatarUrl;
    if (url != null &&
        (url.startsWith('https://') || url.startsWith('http://'))) {
      return ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stack) {
                return _placeholder(context, size);
              },
        ),
      );
    }
    return _placeholder(context, size);
  }

  Widget _placeholder(BuildContext context, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.colors.backgroundTertiary,
      ),
      child: Center(
        child: PhosphorIcon(
          PhosphorIconsFill.phone,
          size: 36,
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}
