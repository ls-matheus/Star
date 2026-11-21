import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/domain/app_icon_choice.dart';
import 'package:star_app/features/settings/presentation/widgets/app_icon_choice_preview.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/settings/providers/preferences/app_icon_settings_provider.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class UserAppIconSettings extends ConsumerWidget {
  const UserAppIconSettings({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = StarLocalizations.of(context);
    final AsyncValue<AppIconSettingsState> settings = ref.watch(
      appIconSettingsProvider,
    );

    return SingleChildScrollView(
      controller: scrollController,
      padding: settingsScrollPadding(context),
      child: settings.when(
        loading: () => const Center(child: StarLoadingSpinner()),
        error: (_, _) => _unsupportedMessage(context, l10n),
        data: (AppIconSettingsState state) {
          if (!state.supported || state.choices.isEmpty) {
            return _unsupportedMessage(context, l10n);
          }
          final AppIconChoice selected = state.selectedChoice()!;
          final String sectionDescription =
              defaultTargetPlatform == TargetPlatform.android
              ? l10n.appIconSectionDescriptionAndroid
              : l10n.appIconSectionDescription;
          return StarSettingsSection(
            title: l10n.appIconSectionTitle,
            description: sectionDescription,
            isFirst: true,
            children: [
              Semantics(
                label: l10n.appIconSectionTitle,
                container: true,
                child: StarRadioGroup<AppIconChoice>(
                  value: selected,
                  onChanged: (AppIconChoice value) => unawaited(
                    _onAppIconChoiceChanged(context, ref, l10n, value),
                  ),
                  items: [
                    for (final AppIconChoice choice in state.choices)
                      StarRadioItem(
                        value: choice,
                        label: choice.label(l10n),
                        leading: AppIconChoicePreview(choice: choice),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _onAppIconChoiceChanged(
  BuildContext context,
  WidgetRef ref,
  StarLocalizations l10n,
  AppIconChoice value,
) async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    final bool? confirmed = await showStarSettingsConfirmSheet(
      context,
      title: l10n.appIconAndroidChangeTitle,
      description: l10n.appIconAndroidChangeDescription,
      confirmLabel: l10n.appIconAndroidChangeConfirm,
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await ref
        .read(appIconSettingsProvider.notifier)
        .setChoiceWithRestart(value);
    return;
  }
  await ref.read(appIconSettingsProvider.notifier).setChoice(value);
}

Widget _unsupportedMessage(BuildContext context, StarLocalizations l10n) {
  return Text(
    l10n.appIconUnsupported,
    style: context.textStyles.bodyMedium.copyWith(
      color: context.colors.textSecondary,
    ),
  );
}
