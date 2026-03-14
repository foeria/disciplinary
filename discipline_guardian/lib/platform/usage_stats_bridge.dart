import 'dart:io';

import 'package:flutter/services.dart';

/// Android UsageStats 原生桥接。
class UsageStatsBridge {
  static const MethodChannel _channel = MethodChannel(
    'discipline_guardian/usage_stats',
  );

  Future<bool> isSupported() async {
    return Platform.isAndroid;
  }

  Future<bool> hasPermission() async {
    if (!Platform.isAndroid) {
      return false;
    }

    final hasPermission = await _channel.invokeMethod<bool>('hasPermission');
    return hasPermission ?? false;
  }

  Future<void> openPermissionSettings() async {
    if (!Platform.isAndroid) {
      return;
    }
    await _channel.invokeMethod<void>('openPermissionSettings');
  }

  Future<Map<String, int>> getTodayUsageMinutes(
    List<String> packageNames,
  ) async {
    if (!Platform.isAndroid || packageNames.isEmpty) {
      return const {};
    }

    final response = await _channel.invokeMethod<Map<Object?, Object?>>(
      'getTodayUsageMinutes',
      <String, Object>{'packageNames': packageNames},
    );

    if (response == null) {
      return const {};
    }

    return response.map((key, value) {
      final packageName = key?.toString() ?? '';
      final minutes = value is int ? value : int.tryParse(value.toString()) ?? 0;
      return MapEntry(packageName, minutes);
    });
  }

  Future<String?> getRecentForegroundPackage() async {
    if (!Platform.isAndroid) {
      return null;
    }

    final packageName = await _channel.invokeMethod<String>(
      'getRecentForegroundApp',
    );
    if (packageName == null || packageName.trim().isEmpty) {
      return null;
    }
    return packageName;
  }
}
