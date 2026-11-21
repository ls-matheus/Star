import 'package:star_app/features/ui/spinner/star_loading_spinner.dart';
import 'package:star_app/material_ui.dart';

const double kNotificationsLoadMoreFooterHeight = 64;

class NotificationsLoadingState extends StatelessWidget {
  const NotificationsLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: StarLoadingSpinner(size: StarLoadingSpinnerSize.medium),
    );
  }
}

class NotificationsLoadMoreFooter extends StatelessWidget {
  const NotificationsLoadMoreFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: kNotificationsLoadMoreFooterHeight,
      child: Center(
        child: StarLoadingSpinner(size: StarLoadingSpinnerSize.small),
      ),
    );
  }
}
