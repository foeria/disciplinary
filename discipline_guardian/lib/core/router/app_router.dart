import 'package:flutter/material.dart';

/// 应用路由配置
class AppRouter {
  AppRouter._();

  /// 路由生成器
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(
              child: Text('页面: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
