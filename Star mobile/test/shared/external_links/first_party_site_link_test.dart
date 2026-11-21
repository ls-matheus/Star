import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/shared/external_links/first_party_site_link.dart';

void main() {
  test('first-party site pages open in the app view', () {
    String open(String url) =>
        withFirstPartySiteAppView(Uri.parse(url)).toString();

    expect(
      open('https://fluxer.com/help/copyright'),
      'https://fluxer.com/help/copyright?view=app',
    );
    expect(
      open('https://star.invalid/terms?x=1#a'),
      'https://star.invalid/terms?x=1&view=app#a',
    );
    expect(
      open('https://star.invalid/operator-pass-terms'),
      'https://star.invalid/operator-pass-terms?view=app',
    );
    expect(
      open('https://star.invalid/channels/@me'),
      'https://star.invalid/channels/@me',
    );
    expect(
      open('https://star.invalid/careers'),
      'https://star.invalid/careers?view=app',
    );
    expect(
      open('https://star.invalid/partners'),
      'https://star.invalid/partners?view=app',
    );
    expect(open('https://star.invalid/donate'), 'https://star.invalid/donate');
    expect(
      open('https://chat.example.org/help'),
      'https://chat.example.org/help',
    );
  });
}
