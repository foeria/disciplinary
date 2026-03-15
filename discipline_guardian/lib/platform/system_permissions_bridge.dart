import 'dart:io';

import 'package:flutter/services.dart';

class SystemPermissionsBridge {
  static const MethodChannel _channel = MethodChannel(
    'discipline_guardian/system_permissions',
  );

  Future<bool> canDrawOverlays() async {
    if (!Platform.isAndroid) {
      return false;
    }
    final result = await _channel.invokeMethod<bool>('canDrawOverlays');
    return result ?? false;
  }

  Future<void> openOverlaySettings() async {
    if (!Platform.isAndroid) {
      return;
    }
    await _channel.invokeMethod<void>('openOverlaySettings');
  }

  Future<bool> areNotificationsEnabled() async {
    if (!Platform.isAndroid) {
      return false;
    }
    final result = await _channel.invokeMethod<bool>('areNotificationsEnabled');
    return result ?? false;
  }

  Future<bool> canRequestNotificationPermission() async {
    if (!Platform.isAndroid) {
      return false;
    }
    final result = await _channel.invokeMethod<bool>(
      'canRequestNotificationPermission',
    );
    return result ?? false;
  }

  Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) {
      return false;
    }
    final result = await _channel.invokeMethod<bool>(
      'requestNotificationPermission',
    );
    return result ?? false;
  }

  Future<void> openNotificationSettings() async {
    if (!Platform.isAndroid) {
      return;
    }
    await _channel.invokeMethod<void>('openNotificationSettings');
  }

  Future<bool> isAccessibilityEnabled() async {
    if (!Platform.isAndroid) {
      return false;
    }
    final result = await _channel.invokeMethod<bool>('isAccessibilityEnabled');
    return result ?? false;
  }

  Future<void> openAccessibilitySettings() async {
    if (!Platform.isAndroid) {
      return;
    }
    await _channel.invokeMethod<void>('openAccessibilitySettings');
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) {
      return false;
    }
    final result =
        await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
    return result ?? false;
  }

  Future<bool> openBatteryOptimizationSettings() async {
    if (!Platform.isAndroid) {
      return false;
    }
    final result =
        await _channel.invokeMethod<bool>('openBatteryOptimizationSettings');
    return result ?? false;
  }

  Future<bool> isKeepAliveEnabled() async {
    if (!Platform.isAndroid) {
      return false;
    }
    final result = await _channel.invokeMethod<bool>('isKeepAliveEnabled');
    return result ?? false;
  }

  Future<bool> isKeepAliveRunning() async {
    if (!Platform.isAndroid) {
      return false;
    }
    final result = await _channel.invokeMethod<bool>('isKeepAliveRunning');
    return result ?? false;
  }

  Future<void> setKeepAliveEnabled(bool enabled) async {
    if (!Platform.isAndroid) {
      return;
    }
    await _channel.invokeMethod<void>(
      'setKeepAliveEnabled',
      <String, Object>{'enabled': enabled},
    );
  }

  Future<void> startKeepAliveService() async {
    if (!Platform.isAndroid) {
      return;
    }
    await _channel.invokeMethod<void>('startKeepAliveService');
  }

  Future<void> stopKeepAliveService() async {
    if (!Platform.isAndroid) {
      return;
    }
    await _channel.invokeMethod<void>('stopKeepAliveService');
  }
}
