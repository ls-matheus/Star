import 'package:star_app/features/chat/utils/chat_spinner_debug.dart';
import 'package:star_app/features/ui/spinner/star_loading_spinner.dart';
import 'package:star_app/material_ui.dart';

class ChatLoadingSpinner extends StatefulWidget {
  const ChatLoadingSpinner({
    required this.reason,
    this.size = StarLoadingSpinnerSize.small,
    super.key,
  });

  final ChatSpinnerReason reason;
  final StarLoadingSpinnerSize size;

  @override
  State<ChatLoadingSpinner> createState() => _ChatLoadingSpinnerState();
}

class _ChatLoadingSpinnerState extends State<ChatLoadingSpinner> {
  @override
  void initState() {
    super.initState();
    assert(() {
      debugLogChatSpinnerMount(widget.reason);
      return true;
    }(), 'Log chat spinner mount for debug builds.');
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ExcludeSemantics(child: StarLoadingSpinner(size: widget.size)),
    );
  }
}
