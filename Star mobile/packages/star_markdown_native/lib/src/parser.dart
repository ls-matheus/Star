// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:star_markdown_native/src/ast.dart';
import 'package:star_markdown_native/src/bindings.dart';
import 'package:star_markdown_native/src/decode_binary.dart';
import 'package:star_markdown_native/src/flags.dart';

final class StarMarkdownParseException implements Exception {
  const StarMarkdownParseException(this.message);
  final String message;

  @override
  String toString() => 'StarMarkdownParseException: $message';
}

String parseStarMarkdownToJson(
  String input, {
  int flags = StarParserFlags.all,
  String emojiContextTsv = '',
}) => _parseWith(input, flags, emojiContextTsv, starMdParse, utf8.decode);

List<MdNode> parseStarMarkdownBinary(
  String input, {
  int flags = StarParserFlags.all,
  String emojiContextTsv = '',
}) => _parseWith(
  input,
  flags,
  emojiContextTsv,
  starMdParseBinary,
  decodeBinaryAst,
);

T _parseWith<T>(
  String input,
  int flags,
  String emojiContextTsv,
  int Function(
    Pointer<Uint8> inputPtr,
    int inputLen,
    int flags,
    Pointer<Uint8> tsvPtr,
    int tsvLen,
    Pointer<StarMdBuffer> out,
  )
  native,
  T Function(Uint8List payload) decode,
) {
  return using((arena) {
    final inputBytes = utf8.encode(input);
    final tsvBytes = utf8.encode(emojiContextTsv);
    final out = arena<StarMdBuffer>();
    final status = native(
      _copyToArena(arena, inputBytes),
      inputBytes.length,
      flags,
      _copyToArena(arena, tsvBytes),
      tsvBytes.length,
      out,
    );
    try {
      if (status != 0) {
        throw StarMarkdownParseException(
          out.ref.error == nullptr
              ? 'unknown native parser failure'
              : utf8.decode(out.ref.error.asTypedList(out.ref.errorLen)),
        );
      }
      return decode(out.ref.data.asTypedList(out.ref.dataLen));
    } finally {
      starMdBufferFree(out);
    }
  });
}

Pointer<Uint8> _copyToArena(Arena arena, Uint8List bytes) {
  final pointer = arena<Uint8>(bytes.isEmpty ? 1 : bytes.length);
  if (bytes.isNotEmpty) {
    pointer.asTypedList(bytes.length).setAll(0, bytes);
  }
  return pointer;
}

List<MdNode> parseStarMarkdown(
  String input, {
  int flags = StarParserFlags.all,
  String emojiContextTsv = '',
}) {
  final json = parseStarMarkdownToJson(
    input,
    flags: flags,
    emojiContextTsv: emojiContextTsv,
  );
  final envelope = jsonDecode(json) as Map<String, Object?>;
  return [
    for (final Object? node in envelope['nodes']! as List<Object?>)
      MdNode.fromJson(node! as Map<String, Object?>),
  ];
}
