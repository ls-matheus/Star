import 'package:star_app/features/favorites/domain/resolved_favorite_entry.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';

String? favoriteEntrySubtitle(
  ResolvedFavoriteEntry entry,
  StarLocalizations l10n,
) {
  final dm = entry.dm;
  if (dm == null) {
    return null;
  }
  if (dm.isGroup) {
    return l10n.dmGroupMemberCount(dm.memberCount);
  }
  return l10n.favoritesDirectMessageSubtitle;
}
