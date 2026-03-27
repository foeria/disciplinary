import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class InterceptionStatus {
  final bool enabled;
  final int blockedPackageCount;
  final String? lastForegroundPackage;
  final String? lastInterceptedPackage;

  const InterceptionStatus({
    required this.enabled,
    required this.blockedPackageCount,
    required this.lastForegroundPackage,
    required this.lastInterceptedPackage,
  });
}

class InterceptionBridge {
  static const MethodChannel _channel = MethodChannel(
    'discipline_guardian/interception',
  );
  static final StreamController<String> _promptSignalsController =
      StreamController<String>.broadcast();
  static bool _callbacksRegistered = false;

  InterceptionBridge() {
    _ensureCallbacksRegistered();
  }

  Stream<String> get promptSignals {
    _ensureCallbacksRegistered();
    return _promptSignalsController.stream;
  }

  void _ensureCallbacksRegistered() {
    if (_callbacksRegistered || !Platform.isAndroid) {
      return;
    }
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'promptPackagePending') {
        final packageName = call.arguments?.toString().trim() ?? '';
        _promptSignalsController.add(packageName);
      }
    });
    _callbacksRegistered = true;
  }

  Future<void> setBlockedPackages(List<String> packages) async {
    if (!Platform.isAndroid) {
      return;
    }
    await _channel.invokeMethod<void>(
      'setBlockedPackages',
      <String, Object>{'packages': packages},
    );
  }

  Future<void> syncUsageMonitoringConfig({
    required List<Map<String, Object?>> rules,
    required bool reminderEnabled,
    required int reminderMinutes,
    required bool notificationsEnabled,
    required bool soundEnabled,
    required bool scheduleEnabled,
    required String workdayStart,
    required String workdayEnd,
    required String weekendStart,
    required String weekendEnd,
  }) async {
    if (!Platform.isAndroid) {
      return;
    }
    await _channel.invokeMethod<void>(
      'syncUsageMonitoringConfig',
      <String, Object?>{
        'rules': rules,
        'reminderEnabled': reminderEnabled,
        'reminderMinutes': reminderMinutes,
        'notificationsEnabled': notificationsEnabled,
        'soundEnabled': soundEnabled,
        'scheduleEnabled': scheduleEnabled,
        'workdayStart': workdayStart,
        'workdayEnd': workdayEnd,
        'weekendStart': weekendStart,
        'weekendEnd': weekendEnd,
      },
    );
  }

  Future<void> setInterceptionEnabled(bool enabled) async {
    if (!Platform.isAndroid) {
      return;
    }
    await _channel.invokeMethod<void>(
      'setInterceptionEnabled',
      <String, Object>{'enabled': enabled},
    );
  }

  Future<String?> getLastAccessibilityForegroundPackage() async {
    if (!Platform.isAndroid) {
      return null;
    }
    return _channel.invokeMethod<String>('getLastAccessibilityForegroundApp');
  }

  Future<String?> getLastInterceptedPackage() async {
    if (!Platform.isAndroid) {
      return null;
    }
    return _channel.invokeMethod<String>('getLastInterceptedPackage');
  }

  Future<String?> consumeLastInterceptedPackage() async {
    if (!Platform.isAndroid) {
      return null;
    }
    return _channel.invokeMethod<String>('consumeLastInterceptedPackage');
  }

  Future<InterceptionStatus> getInterceptionStatus() async {
    if (!Platform.isAndroid) {
      return const InterceptionStatus(
        enabled: false,
        blockedPackageCount: 0,
        lastForegroundPackage: null,
        lastInterceptedPackage: null,
      );
    }

    final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
      'getInterceptionStatus',
    );

    if (raw == null) {
      return const InterceptionStatus(
        enabled: false,
        blockedPackageCount: 0,
        lastForegroundPackage: null,
        lastInterceptedPackage: null,
      );
    }

    final enabled = raw['enabled'] == true;
    final blockedCount = raw['blockedPackageCount'] is int
        ? raw['blockedPackageCount'] as int
        : int.tryParse(raw['blockedPackageCount']?.toString() ?? '0') ?? 0;

    return InterceptionStatus(
      enabled: enabled,
      blockedPackageCount: blockedCount,
      lastForegroundPackage: raw['lastForegroundPackage']?.toString(),
      lastInterceptedPackage: raw['lastInterceptedPackage']?.toString(),
    );
  }

  Future<String?> consumePromptPackage() async {
    if (!Platform.isAndroid) {
      return null;
    }
    return _channel.invokeMethod<String>('consumePromptPackage');
  }

  Future<void> resetPromptState(String packageName) async {
    if (!Platform.isAndroid) {
      return;
    }
    await _channel.invokeMethod<void>(
      'resetPromptState',
      <String, Object>{'packageName': packageName},
    );
  }

  Future<bool> launchAppByPackage(String packageName) async {
    if (!Platform.isAndroid || packageName.trim().isEmpty) {
      return false;
    }
    final launched = await _channel.invokeMethod<bool>(
      'launchAppByPackage',
      <String, Object>{'packageName': packageName},
    );
    return launched == true;
  }

  Future<bool> moveGuardianToBackground() async {
    if (!Platform.isAndroid) {
      return false;
    }
    final moved = await _channel.invokeMethod<bool>('moveGuardianToBackground');
    return moved == true;
  }

  Future<bool> openHomeScreen() async {
    if (!Platform.isAndroid) {
      return false;
    }
    final opened = await _channel.invokeMethod<bool>('openHomeScreen');
    return opened == true;
  }
}
