import 'package:star_app/features/settings/presentation/widgets/guild/webhooks/guild_webhooks_header.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/ui/spinner/star_loading_spinner.dart';
import 'package:star_app/material_ui.dart';

class GuildWebhooksStatusBody extends StatelessWidget {
  const GuildWebhooksStatusBody({
    required this.child,
    this.scrollController,
    super.key,
  });

  final Widget child;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.zero,
      children: <Widget>[
        const GuildWebhooksHeader(),
        Padding(padding: settingsScrollPadding(context), child: child),
      ],
    );
  }
}

class GuildWebhooksLoadingBody extends StatelessWidget {
  const GuildWebhooksLoadingBody({this.scrollController, super.key});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return GuildWebhooksStatusBody(
      scrollController: scrollController,
      child: const Center(child: StarLoadingSpinner()),
    );
  }
}
