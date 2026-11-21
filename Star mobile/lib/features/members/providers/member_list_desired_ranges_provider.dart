import 'package:star_app/features/members/domain/member_list_range_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'member_list_desired_ranges_provider.g.dart';

String memberListDesiredRangesKey(String guildId, String channelId) {
  return '$guildId$channelId';
}

@Riverpod(keepAlive: true)
class MemberListDesiredRanges extends _$MemberListDesiredRanges {
  @override
  Map<String, List<MemberListRange>> build(String accountUserId) =>
      <String, List<MemberListRange>>{};

  void setRanges({
    required String guildId,
    required String channelId,
    required List<MemberListRange> ranges,
  }) {
    final String key = memberListDesiredRangesKey(guildId, channelId);
    final List<MemberListRange> normalized = normalizeMemberListRanges(ranges);
    final Map<String, List<MemberListRange>> current =
        Map<String, List<MemberListRange>>.from(state);
    final List<MemberListRange>? existing = current[key];
    if (existing != null && areMemberListRangesEqual(existing, normalized)) {
      return;
    }
    current[key] = normalized;
    state = current;
  }

  void clearChannel({required String guildId, required String channelId}) {
    if (!ref.mounted) {
      return;
    }
    final String key = memberListDesiredRangesKey(guildId, channelId);
    if (!state.containsKey(key)) {
      return;
    }
    state = Map<String, List<MemberListRange>>.from(state)..remove(key);
  }

  void clearAll() {
    if (state.isEmpty) {
      return;
    }
    state = <String, List<MemberListRange>>{};
  }
}
