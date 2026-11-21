import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/app/account_user_id.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/presentation/widgets/privacy/privacy_activity_sharing_section.dart';
import 'package:star_app/features/settings/presentation/widgets/privacy/privacy_communication_section.dart';
import 'package:star_app/features/settings/presentation/widgets/privacy/privacy_connections_section.dart';
import 'package:star_app/features/settings/presentation/widgets/privacy/privacy_data_request_section.dart';
import 'package:star_app/features/settings/presentation/widgets/privacy/privacy_profile_section.dart';
import 'package:star_app/features/settings/presentation/widgets/privacy/privacy_sensitive_content_section.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/settings/providers/view_models/privacy_dashboard_view_model.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class UserPrivacyDashboard extends ConsumerWidget {
  const UserPrivacyDashboard({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      privacyDashboardViewModelProvider(watchAccountUserId(ref)),
    );
    final l10n = StarLocalizations.of(context);
    final layout = context.layout;

    if (state.isLoading) {
      return const Center(child: StarLoadingSpinner());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.privacyDashboardLoadFailed,
              style: context.textStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: layout.s4),
            SizedBox(
              width: double.infinity,
              child: StarButton.primary(
                label: l10n.privacyDashboardRetry,
                onPressedAsync: ref
                    .read(
                      privacyDashboardViewModelProvider(
                        readAccountUserId(ref),
                      ).notifier,
                    )
                    .loadSettings,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: scrollController,
      padding: settingsScrollPadding(context),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PrivacyProfileSection(),
          PrivacyConnectionsSection(),
          PrivacyCommunicationSection(),
          PrivacyActivitySharingSection(),
          PrivacySensitiveContentSection(),
          PrivacyDataExportSection(),
          PrivacyDataDeletionSection(),
        ],
      ),
    );
  }
}
