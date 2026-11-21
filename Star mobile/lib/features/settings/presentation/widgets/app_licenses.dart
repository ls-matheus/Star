import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/settings/utils/app_licenses_data.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

Future<void> showAppLicensePackageSheet(
  BuildContext context, {
  required String packageName,
  required List<LicenseEntry> entries,
}) {
  return StarBottomSheet.showScrollable<void>(
    context,
    title: packageName,
    useRootNavigator: true,
    builder: (sheetContext, scrollController, _) {
      final colors = sheetContext.colors;

      return SingleChildScrollView(
        controller: scrollController,
        padding: settingsSheetScrollPadding(sheetContext),
        child: SelectableText(
          formatAppLicenseEntries(entries),
          style: sheetContext.textStyles.bodySmall.copyWith(
            color: colors.textPrimary,
            height: 1.5,
          ),
        ),
      );
    },
  );
}

class AppLicenses extends StatefulWidget {
  const AppLicenses({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  State<AppLicenses> createState() => _AppLicensesState();
}

class _AppLicensesState extends State<AppLicenses> {
  late Future<AppLicensesData> _licensesFuture;

  @override
  void initState() {
    super.initState();
    _licensesFuture = loadAppLicensesData();
  }

  void _reloadLicenses() {
    setState(() {
      _licensesFuture = loadAppLicensesData();
    });
  }

  void _openPackage(String packageName, List<LicenseEntry> entries) {
    unawaited(
      showAppLicensePackageSheet(
        context,
        packageName: packageName,
        entries: entries,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppLicensesData>(
      future: _licensesFuture,
      builder: (BuildContext context, AsyncSnapshot<AppLicensesData> snapshot) {
        final Widget body = switch (snapshot.connectionState) {
          ConnectionState.none || ConnectionState.waiting => const Center(
            child: StarLoadingSpinner(),
          ),
          ConnectionState.active => const Center(child: StarLoadingSpinner()),
          ConnectionState.done => _buildLoadedBody(context, snapshot),
        };

        return SingleChildScrollView(
          controller: widget.scrollController,
          padding: settingsScrollPadding(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 1),
            child: body,
          ),
        );
      },
    );
  }

  Widget _buildLoadedBody(
    BuildContext context,
    AsyncSnapshot<AppLicensesData> snapshot,
  ) {
    if (snapshot.hasError) {
      return _AppLicensesErrorState(onRetry: _reloadLicenses);
    }

    final AppLicensesData? data = snapshot.data;
    if (data == null) {
      return _AppLicensesErrorState(onRetry: _reloadLicenses);
    }

    return _AppLicensesList(data: data, onPackageSelected: _openPackage);
  }
}

class _AppLicensesList extends StatelessWidget {
  const _AppLicensesList({required this.data, required this.onPackageSelected});

  final AppLicensesData data;
  final void Function(String packageName, List<LicenseEntry> entries)
  onPackageSelected;

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);

    return StarSettingsSection(
      title: l10n.userSettingsNavAppLicenses,
      description: l10n.userSettingsAppLicensesDescription,
      isFirst: true,
      density: StarSettingsSectionDensity.compact,
      children: [
        StarMenuGroup(
          children: [
            for (final String packageName in data.packages)
              StarBottomSheetSubmenuItem(
                label: packageName,
                hint: l10n.userSettingsAppLicensesPackageCount(
                  data.licenseCountForPackage(packageName),
                ),
                onTap: () => onPackageSelected(
                  packageName,
                  data.entriesForPackage(packageName),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AppLicensesErrorState extends StatelessWidget {
  const _AppLicensesErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final colors = context.colors;
    final l10n = StarLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: layout.s8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(
            PhosphorIconsFill.scroll,
            size: 48,
            color: colors.textPrimaryMuted,
          ),
          SizedBox(height: layout.s3),
          Text(
            l10n.userSettingsAppLicensesLoadError,
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textPrimaryMuted,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: layout.s4),
          StarButton.primary(label: l10n.retry, onPressed: onRetry),
        ],
      ),
    );
  }
}
