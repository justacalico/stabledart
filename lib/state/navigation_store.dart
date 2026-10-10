import 'package:flutter/foundation.dart';

class NavigationStore extends ChangeNotifier {
  int _index = 0;
  bool _updateBannerVisible = true;
  int _activityBadgeCount = 0;

  int get index => _index;
  bool get updateBannerVisible => _updateBannerVisible;
  int get activityBadgeCount => _activityBadgeCount;

  void goTo(int index) {
    if (_index == index) return;
    _index = index;
    notifyListeners();
  }

  void dismissUpdateBanner() {
    _updateBannerVisible = false;
    notifyListeners();
  }

  void setActivityBadge(int count) {
    _activityBadgeCount = count;
    notifyListeners();
  }
}
