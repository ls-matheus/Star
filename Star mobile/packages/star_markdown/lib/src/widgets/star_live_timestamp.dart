import 'dart:async';

import 'package:material_ui/material_ui.dart';

class StarRelativeTimeTick extends ChangeNotifier {
  StarRelativeTimeTick._();

  static final StarRelativeTimeTick instance = StarRelativeTimeTick._();

  Timer? _timer;
  int _refCount = 0;

  void retain() {
    _refCount++;
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  void release() {
    if (_refCount == 0) {
      return;
    }
    _refCount--;
    if (_refCount > 0) {
      return;
    }
    _timer?.cancel();
    _timer = null;
  }
}

class StarLiveTimestamp extends StatefulWidget {
  const StarLiveTimestamp({
    required this.format,
    required this.style,
    super.key,
  });

  final String Function() format;
  final TextStyle style;

  @override
  State<StarLiveTimestamp> createState() => _StarLiveTimestampState();
}

class _StarLiveTimestampState extends State<StarLiveTimestamp> {
  late String _text;

  @override
  void initState() {
    super.initState();
    _text = widget.format();
    StarRelativeTimeTick.instance
      ..retain()
      ..addListener(_onTick);
  }

  @override
  void didUpdateWidget(covariant StarLiveTimestamp oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String next = widget.format();
    if (next != _text) {
      _text = next;
    }
  }

  @override
  void dispose() {
    StarRelativeTimeTick.instance
      ..removeListener(_onTick)
      ..release();
    super.dispose();
  }

  void _onTick() {
    if (!mounted) {
      return;
    }
    final String next = widget.format();
    if (next == _text) {
      return;
    }
    setState(() {
      _text = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _text,
      style: widget.style,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.clip,
    );
  }
}
