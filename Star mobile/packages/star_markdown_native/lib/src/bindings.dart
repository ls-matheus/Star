// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:ffi';
import 'dart:io';

final class StarMdBuffer extends Struct {
  external Pointer<Uint8> data;

  @Size()
  external int dataLen;

  external Pointer<Uint8> error;

  @Size()
  external int errorLen;
}

typedef _ParseC =
    Uint32 Function(
      Pointer<Uint8>,
      Size,
      Uint32,
      Pointer<Uint8>,
      Size,
      Pointer<StarMdBuffer>,
    );

typedef _ParseDart =
    int Function(
      Pointer<Uint8>,
      int,
      int,
      Pointer<Uint8>,
      int,
      Pointer<StarMdBuffer>,
    );

typedef _FreeDart = void Function(Pointer<StarMdBuffer>);

int starMdParse(
  Pointer<Uint8> inputPtr,
  int inputLen,
  int flags,
  Pointer<Uint8> tsvPtr,
  int tsvLen,
  Pointer<StarMdBuffer> out,
) {
  if (_loadsBundledFramework) {
    return _bundled().parse(inputPtr, inputLen, flags, tsvPtr, tsvLen, out);
  }
  return _nativeStarMdParse(inputPtr, inputLen, flags, tsvPtr, tsvLen, out);
}

int starMdParseBinary(
  Pointer<Uint8> inputPtr,
  int inputLen,
  int flags,
  Pointer<Uint8> tsvPtr,
  int tsvLen,
  Pointer<StarMdBuffer> out,
) {
  if (_loadsBundledFramework) {
    return _bundled().parseBinary(
      inputPtr,
      inputLen,
      flags,
      tsvPtr,
      tsvLen,
      out,
    );
  }
  return _nativeStarMdParseBinary(
    inputPtr,
    inputLen,
    flags,
    tsvPtr,
    tsvLen,
    out,
  );
}

void starMdBufferFree(Pointer<StarMdBuffer> out) {
  if (_loadsBundledFramework) {
    _bundled().free(out);
    return;
  }
  _nativeStarMdBufferFree(out);
}

@Native<
  Uint32 Function(
    Pointer<Uint8>,
    Size,
    Uint32,
    Pointer<Uint8>,
    Size,
    Pointer<StarMdBuffer>,
  )
>(symbol: 'star_md_parse')
external int _nativeStarMdParse(
  Pointer<Uint8> inputPtr,
  int inputLen,
  int flags,
  Pointer<Uint8> tsvPtr,
  int tsvLen,
  Pointer<StarMdBuffer> out,
);

@Native<
  Uint32 Function(
    Pointer<Uint8>,
    Size,
    Uint32,
    Pointer<Uint8>,
    Size,
    Pointer<StarMdBuffer>,
  )
>(symbol: 'star_md_parse_binary')
external int _nativeStarMdParseBinary(
  Pointer<Uint8> inputPtr,
  int inputLen,
  int flags,
  Pointer<Uint8> tsvPtr,
  int tsvLen,
  Pointer<StarMdBuffer> out,
);

@Native<Void Function(Pointer<StarMdBuffer>)>(symbol: 'star_md_buffer_free')
external void _nativeStarMdBufferFree(Pointer<StarMdBuffer> out);

bool get _loadsBundledFramework {
  return Platform.isMacOS &&
      Platform.resolvedExecutable.contains('.app/Contents/MacOS/');
}

_BundledParser? _openParser;

_BundledParser _bundled() {
  final cached = _openParser;
  if (cached != null) {
    return cached;
  }
  final opened = _BundledParser.open();
  _openParser = opened;
  return opened;
}

final class _BundledParser {
  _BundledParser(DynamicLibrary library)
    : parse = library.lookupFunction<_ParseC, _ParseDart>('star_md_parse'),
      parseBinary = library.lookupFunction<_ParseC, _ParseDart>(
        'star_md_parse_binary',
      ),
      free = library
          .lookupFunction<Void Function(Pointer<StarMdBuffer>), _FreeDart>(
            'star_md_buffer_free',
          );

  factory _BundledParser.open() {
    return _BundledParser(DynamicLibrary.open(_frameworkBinaryPath()));
  }

  final _ParseDart parse;
  final _ParseDart parseBinary;
  final _FreeDart free;
}

String _frameworkBinaryPath() {
  const framework = 'star_markdown_parser.framework/star_markdown_parser';
  final executableDir = File(Platform.resolvedExecutable).parent;
  final bundleDir = Platform.isIOS ? executableDir : executableDir.parent;
  return '${bundleDir.path}/Frameworks/$framework';
}
