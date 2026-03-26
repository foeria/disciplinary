import 'dart:io';

import 'package:flutter/services.dart';

class DeviceInstalledApp {
  final String appName;
  final String packageName;
  final DateTime? installedAt;

  const DeviceInstalledApp({
    required this.appName,
    required this.packageName,
    required this.installedAt,
  });
}

class DeviceAppsBridge {
  static const MethodChannel _channel = MethodChannel(
    'discipline_guardian/device_apps',
  );

  Future<List<DeviceInstalledApp>> getInstalledApps() async {
    if (!Platform.isAndroid) {
      return const <DeviceInstalledApp>[];
    }

    final response = await _channel.invokeListMethod<dynamic>('getInstalledApps');
    final rawApps = response ?? const <dynamic>[];

    return rawApps
        .whereType<Map>()
        .map((app) {
          final appName = (app['appName'] ?? '').toString().trim();
          final packageName = (app['packageName'] ?? '').toString().trim();
          if (appName.isEmpty || packageName.isEmpty) {
            return null;
          }
          return DeviceInstalledApp(
            appName: appName,
            packageName: packageName,
            installedAt: _parseInstalledAt(app['firstInstallTime']),
          );
        })
        .whereType<DeviceInstalledApp>()
        .toList(growable: false);
  }

  DateTime? _parseInstalledAt(dynamic raw) {
    if (raw is int && raw > 0) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }
    final parsed = int.tryParse(raw?.toString() ?? '');
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(parsed);
  }
}
