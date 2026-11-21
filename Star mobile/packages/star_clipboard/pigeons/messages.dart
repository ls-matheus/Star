// ignore_for_file: document_ignores

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'star_clipboard',
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut: 'android/src/main/kotlin/com/star/clipboard/Messages.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.star.clipboard',
      errorClassName: 'StarClipboardError',
    ),
    swiftOut:
        'darwin/star_clipboard/Sources/star_clipboard/Messages.g.swift',
    swiftOptions: SwiftOptions(errorClassName: 'StarClipboardError'),
    cppHeaderOut: 'windows/messages.g.h',
    cppSourceOut: 'windows/messages.g.cpp',
    cppOptions: CppOptions(namespace: 'star_clipboard'),
    gobjectHeaderOut: 'linux/messages.g.h',
    gobjectSourceOut: 'linux/messages.g.cc',
    gobjectOptions: GObjectOptions(module: 'StarClipboard'),
  ),
)
class NativeClipboardItem {
  NativeClipboardItem({this.mimeType, this.name, this.data, this.path});

  String? mimeType;
  String? name;
  Uint8List? data;
  String? path;
}

@HostApi()
abstract class ClipboardHostApi {
  @async
  List<NativeClipboardItem> readItems(List<String> mimeTypes, int maxItems);

  @async
  String? readText();
}
