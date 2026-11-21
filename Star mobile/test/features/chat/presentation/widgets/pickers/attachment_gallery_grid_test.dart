import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/data/attachment_gallery_source.dart';
import 'package:star_app/features/chat/presentation/widgets/pickers/attachment_gallery_grid.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

import '../../../../../helpers/test_l10n.dart';

void main() {
  testWidgets('camera tile and gallery selection respond to taps', (
    tester,
  ) async {
    final List<String> tapped = <String>[];
    int cameraTaps = 0;
    final ScrollController scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    final colorTheme = buildDarkColorTheme();
    await tester.pumpWidget(
      MaterialApp(
        locale: kTestLocale,
        localizationsDelegates: starLocalizationsDelegates,
        supportedLocales: StarLocalizations.supportedLocales,
        theme: buildStarTheme(
          colorTheme: colorTheme,
          textTheme: StarTextTheme.fromColors(colorTheme),
          layoutTheme: StarLayoutTheme.scaled(),
        ),
        home: Scaffold(
          body: AttachmentGalleryGrid(
            items: const <AttachmentGalleryItem>[
              AttachmentGalleryItem(id: 'photo-1', isVideo: false),
              AttachmentGalleryItem(
                id: 'vid-1',
                isVideo: true,
                duration: Duration(seconds: 12),
              ),
            ],
            selectedAssetIds: const <String>{'photo-1'},
            thumbnailLoader: (String id) async => Uint8List(0),
            onCameraPressed: () => cameraTaps += 1,
            onAssetPressed: (AttachmentGalleryItem item) => tapped.add(item.id),
            scrollController: scrollController,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(PhosphorIconsFill.camera));
    await tester.tap(find.text('0:12'));
    expect(cameraTaps, 1);
    expect(tapped, <String>['vid-1']);
    expect(find.byIcon(PhosphorIconsBold.check), findsOneWidget);
  });
}
