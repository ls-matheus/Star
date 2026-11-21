import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/features/settings/presentation/sheets/profile_local_time_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';
import 'package:star_app/features/ui/settings/star_settings_section.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class ProfileLocalTimeSettingsSection extends ConsumerWidget {
  const ProfileLocalTimeSettingsSection({required this.disabled, super.key});

  final bool disabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final String productName = ref.watch(
      instanceRuntimeConfigProvider.select((config) => config.productName),
    );

    return StarSettingsSection(
      title: l10n.profileLocalTimeSettingsTitle,
      description: l10n.profileLocalTimeSettingsSummary(productName),
      children: <Widget>[
        StarButton.secondary(
          label: l10n.profileLocalTimeEditButton,
          size: StarButtonSize.small,
          fitContent: true,
          onPressed: disabled
              ? null
              : () {
                  unawaited(
                    ProfileLocalTimeSheet.show(context, disabled: disabled),
                  );
                },
        ),
      ],
    );
  }
}
