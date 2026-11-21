import 'dart:ui' show clampDouble;

import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoSliverRefreshControl, RefreshIndicatorMode;
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/features/ui/spinner/star_loading_spinner.dart';
import 'package:star_app/material_ui.dart';

class StarRefreshScrollView extends StatelessWidget {
  const StarRefreshScrollView({
    required this.onRefresh,
    required this.slivers,
    super.key,
    this.controller,
  });

  final Future<void> Function() onRefresh;
  final List<Widget> slivers;
  final ScrollController? controller;

  static Widget buildSpinnerIndicator({
    required RefreshIndicatorMode refreshState,
    required double pulledExtent,
    required double refreshTriggerPullDistance,
  }) {
    final double percentageComplete = clampDouble(
      pulledExtent / refreshTriggerPullDistance,
      0,
      1,
    );
    final Widget spinner = switch (refreshState) {
      RefreshIndicatorMode.inactive => const SizedBox.shrink(),
      RefreshIndicatorMode.drag => StarLoadingSpinner(
        size: StarLoadingSpinnerSize.medium,
        revealProgress: percentageComplete,
      ),
      RefreshIndicatorMode.armed || RefreshIndicatorMode.refresh =>
        const StarLoadingSpinner(size: StarLoadingSpinnerSize.medium),
      RefreshIndicatorMode.done => Opacity(
        opacity: percentageComplete,
        child: const StarLoadingSpinner(
          size: StarLoadingSpinnerSize.medium,
        ),
      ),
    };
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(top: 15, left: 0, right: 0, child: Center(child: spinner)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: <Widget>[
        if (!StarBottomSheet.isInSheet(context))
          CupertinoSliverRefreshControl(
            onRefresh: onRefresh,
            builder:
                (
                  BuildContext context,
                  RefreshIndicatorMode refreshState,
                  double pulledExtent,
                  double refreshTriggerPullDistance,
                  double refreshIndicatorExtent,
                ) {
                  return buildSpinnerIndicator(
                    refreshState: refreshState,
                    pulledExtent: pulledExtent,
                    refreshTriggerPullDistance: refreshTriggerPullDistance,
                  );
                },
          ),
        ...slivers,
      ],
    );
  }
}

@StarWidgetPreview(name: 'Default', group: 'StarRefreshScrollView')
Widget starRefreshScrollViewPreview() {
  return SizedBox(
    height: 220,
    width: 280,
    child: ColoredBox(
      color: const Color(0xFF2B2D31),
      child: StarRefreshScrollView(
        onRefresh: () async {
          await Future<void>.delayed(const Duration(seconds: 1));
        },
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List<Widget>.generate(
                  8,
                  (int i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Builder(
                      builder: (BuildContext context) => Text(
                        'Pull from top — row ${i + 1}',
                        style: context.textStyles.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
