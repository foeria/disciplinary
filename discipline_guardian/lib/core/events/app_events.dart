import 'package:flutter/foundation.dart';

/// In-app event bus for lightweight page refresh notifications.
class AppEvents {
  AppEvents._();

  static final ValueNotifier<int> homeRefreshTick = ValueNotifier<int>(0);
  static final ValueNotifier<int> appsRefreshTick = ValueNotifier<int>(0);
  static final ValueNotifier<int> statsRefreshTick = ValueNotifier<int>(0);

  static void notifyHomeRefresh() {
    homeRefreshTick.value = homeRefreshTick.value + 1;
  }

  static void notifyAppsRefresh() {
    appsRefreshTick.value = appsRefreshTick.value + 1;
  }

  static void notifyStatsRefresh() {
    statsRefreshTick.value = statsRefreshTick.value + 1;
  }
}
