import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/utils/clipboard_utils.dart';

import '../../helpers/test_l10n.dart';

void main() {
  testWidgets('copyToClipboard writes value and shows toast', (tester) async {
    final clipboardWrites = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardWrites.add((call.arguments as Map)['text']);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    WidgetRef? capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: kTestLocale,
          localizationsDelegates: starLocalizationsDelegates,
          supportedLocales: StarLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () {
                  capturedRef = ref;
                  unawaited(
                    copyToClipboard(context: context, value: 'test-value'),
                  );
                },
                child: const Text('Copy'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();

    expect(clipboardWrites, ['test-value']);

    final entries = capturedRef!.read(toastProvider);
    expect(entries, hasLength(1));
    expect(entries.single.toast.message, 'Copied to clipboard');
    expect(entries.single.toast.variant, StarToastVariant.success);
  });

  testWidgets('copyToClipboard uses custom message', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    WidgetRef? capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: kTestLocale,
          localizationsDelegates: starLocalizationsDelegates,
          supportedLocales: StarLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () {
                  capturedRef = ref;
                  unawaited(
                    copyToClipboard(
                      context: context,
                      value: 'value',
                      message: 'Custom copied',
                      variant: StarToastVariant.info,
                    ),
                  );
                },
                child: const Text('Copy'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();

    final entries = capturedRef!.read(toastProvider);
    expect(entries.single.toast.message, 'Custom copied');
    expect(entries.single.toast.variant, StarToastVariant.info);
  });
}
