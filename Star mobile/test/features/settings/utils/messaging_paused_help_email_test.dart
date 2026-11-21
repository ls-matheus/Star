import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/features/settings/utils/messaging_paused_help_email.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';

void main() {
  test('fills the support email with the account facts', () {
    final MessagingPausedHelpEmail email = buildMessagingPausedHelpEmail(
      l10n: lookupStarLocalizations(const Locale('en')),
      accountId: '1425000000000000000',
      userTag: 'marty#0001',
      createdAt: DateTime.utc(2026, 10, 7, 12, 30),
      country: '  Philippines ',
    );
    expect(
      email.body,
      <String>[
        "My text didn't go through",
        '',
        'Account ID: 1425000000000000000',
        'Username: marty#0001',
        'Account created: 2026-10-07T12:30:00.000Z',
        'Country: Philippines',
      ].join('\n'),
    );
    final Uri uri = Uri.parse(email.mailto);
    expect(uri.scheme, 'mailto');
    expect(uri.path, 'support@star.invalid');
    expect(uri.queryParameters['subject'], "My text didn't go through");
    expect(uri.queryParameters['body'], email.body);
    expect(email.mailto, isNot(contains('+')));
  });
}
