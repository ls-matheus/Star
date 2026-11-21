enum HomeQuickAction {
  dms(type: 'star.dms', icon: 'quick_action_dms'),
  search(type: 'star.search', icon: 'quick_action_search'),
  notifications(
    type: 'star.notifications',
    icon: 'quick_action_notifications',
  );

  const HomeQuickAction({required this.type, required this.icon});

  final String type;
  final String icon;

  static HomeQuickAction? tryParse(String type) {
    for (final HomeQuickAction action in values) {
      if (action.type == type) {
        return action;
      }
    }
    return null;
  }
}
