import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class SystemDmComposerBarrier extends ConsumerWidget {
  const SystemDmComposerBarrier({this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final String body =
        message ??
        l10n.systemDmComposerBarrier(
          ref.watch(
            instanceRuntimeConfigProvider.select(
              (config) => config.productName,
            ),
          ),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            color: context.colors.chatInputBackground,
            border: Border(
              top: BorderSide(color: context.colors.userAreaDividerColor),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: PhosphorIcon(
                  PhosphorIconsFill.info,
                  size: 18,
                  color: context.colors.textSecondary,
                ),
              ),
              Expanded(
                child: Text(
                  body,
                  style: context.textStyles.bodyMedium.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: MediaQuery.paddingOf(context).bottom,
          decoration: BoxDecoration(color: context.colors.chatInputBackground),
        ),
      ],
    );
  }
}
