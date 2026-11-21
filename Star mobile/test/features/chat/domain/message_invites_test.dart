import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/instance/instance_endpoints.dart';
import 'package:star_app/features/chat/domain/message.dart';

void main() {
  Message msg(String content) => Message(
    id: '1',
    channelId: '2',
    authorId: '3',
    authorName: 'author',
    content: content,
    timestamp: DateTime.utc(2026),
  );

  group('Message.invites', () {
    test('returns empty when no invite links', () {
      expect(msg('hello world').invites, isEmpty);
    });

    test('extracts a single star.gg code', () {
      expect(msg('join https://star.gg/abcd').invites, <String>['abcd']);
    });

    test('extracts a star.invalid/invite code', () {
      expect(msg('https://web.star.invalid/invite/wxyz here').invites, <String>[
        'wxyz',
      ]);
    });

    test('ignores star.gg/invite/ paths', () {
      expect(msg('https://star.gg/invite/nope').invites, isEmpty);
    });

    test('extracts multiple distinct codes', () {
      expect(msg('star.gg/one and star.gg/two').invites, <String>[
        'one',
        'two',
      ]);
    });

    test('dedupes repeated codes', () {
      expect(msg('star.gg/dup star.gg/dup').invites, <String>['dup']);
    });

    test('caps at 10 codes', () {
      final content = List<String>.generate(
        15,
        (int i) => 'star.gg/code$i',
      ).join(' ');
      expect(msg(content).invites, hasLength(10));
    });

    test('ignores invite inside fenced code block', () {
      expect(msg('```\nhttps://star.gg/abcd\n```').invites, isEmpty);
    });

    test('ignores invite inside inline code', () {
      expect(msg('use `star.gg/abcd` here').invites, isEmpty);
    });

    test('ignores masked invite link inside fenced code block', () {
      expect(
        msg('```\n[join](<https://star.gg/abcd>)\n```').invites,
        isEmpty,
      );
    });

    test('extracts a star.invalid/invite code', () {
      expect(msg('https://star.invalid/invite/abcd').invites, <String>['abcd']);
    });

    test('a self-hosted instance matches its own invite links only', () {
      addTearDown(InstanceEndpoints.resetToDefaults);
      InstanceEndpoints.selfHosted = true;
      InstanceEndpoints.invite = 'http://192.168.1.20:8080/invite';
      InstanceEndpoints.webApp = 'http://192.168.1.20:8080';
      expect(
        msg(
          'http://192.168.1.20:8080/invite/Ab12Cd34 and star.gg/other',
        ).invites,
        <String>['Ab12Cd34'],
      );
    });

    test('still extracts invite outside code block in same message', () {
      expect(
        msg('```star.gg/hidden``` join star.gg/plain').invites,
        <String>['plain'],
      );
    });
  });

  group('Message.themes', () {
    test('returns empty when no theme links', () {
      expect(msg('no themes here').themes, isEmpty);
    });

    test('extracts a theme id', () {
      expect(
        msg('check https://web.star.invalid/theme/dark1 out').themes,
        <String>['dark1'],
      );
    });

    test('dedupes repeated theme ids', () {
      expect(
        msg(
          'https://web.star.invalid/theme/xy https://web.star.invalid/theme/xy',
        ).themes,
        <String>['xy'],
      );
    });

    test('ignores theme link inside fenced code block', () {
      expect(
        msg('```\nhttps://web.star.invalid/theme/dark1\n```').themes,
        isEmpty,
      );
    });

    test('extracts theme ids from other official theme hosts', () {
      expect(
        msg(
          'https://star.invalid/theme/aa star.invalid/theme/bb '
          'https://canary.star.invalid/theme/cc',
        ).themes,
        <String>['aa', 'bb', 'cc'],
      );
    });

    test('ignores theme paths on unrelated hosts', () {
      expect(msg('https://example.com/theme/dark1').themes, isEmpty);
    });
  });
}
