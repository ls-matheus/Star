import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/features/ui/qr_code/star_qr_code.dart';
import 'package:star_app/material_ui.dart';

void main() {
  testWidgets('renders a square QR of the requested size', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: StarQrCode(
            data: 'otpauth://totp/Star:alice?secret=ABCDEF&issuer=Star',
            size: 160,
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsOneWidget);
    expect(tester.getSize(find.byType(StarQrCode)), const Size(160, 160));
  });

  testWidgets('exposes a semantic image label when provided', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: StarQrCode(
          data: 'otpauth://totp/Star:alice?secret=ABCDEF&issuer=Star',
          semanticLabel: 'Scan the QR code',
        ),
      ),
    );

    expect(find.bySemanticsLabel('Scan the QR code'), findsOneWidget);
  });
}
