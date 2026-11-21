import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/features/chat/utils/embeds/embed_animated_image_url.dart';

void main() {
  test('animatedEmbedImageUrl requests the animated webp transform', () {
    final url = animatedEmbedImageUrl(
      'https://starusercontent.com/external/sig/v2/xyz',
    );
    expect(url, startsWith('https://starusercontent.com/'));
    expect(url, contains('format=webp'));
    expect(url, contains('animated=true'));
  });

  test('staticEmbedImageUrl requests the static webp transform', () {
    final url = staticEmbedImageUrl(
      'https://starusercontent.com/external/sig/v2/abc',
    );
    expect(url, contains('format=webp'));
    expect(url, contains('animated=false'));
  });
}
