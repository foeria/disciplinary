import 'package:flutter/material.dart';
import 'pink_theme.dart';
import 'blue_theme.dart';
import 'purple_theme.dart';
import 'green_theme.dart';
import 'yellow_theme.dart';

/// 主题类型枚举
enum ThemeType {
  pink,
  blue,
  purple,
  green,
  yellow,
}

/// 主题管理器
class AppTheme {
  static ThemeType _currentTheme = ThemeType.pink;

  /// 获取当前主题
  static ThemeType get currentTheme => _currentTheme;

  /// 设置主题
  static void setTheme(ThemeType theme) {
    _currentTheme = theme;
  }

  /// 获取当前主题数据
  static ThemeData get themeData {
    return themeDataFor(_currentTheme);
  }

  static ThemeData themeDataFor(ThemeType theme) {
    switch (theme) {
      case ThemeType.pink:
        return PinkTheme.themeData;
      case ThemeType.blue:
        return BlueTheme.themeData;
      case ThemeType.purple:
        return PurpleTheme.themeData;
      case ThemeType.green:
        return GreenTheme.themeData;
      case ThemeType.yellow:
        return YellowTheme.themeData;
    }
  }

  /// 获取当前主题主色
  static Color get primaryColor {
    return primaryColorFor(_currentTheme);
  }

  static Color primaryColorFor(ThemeType theme) {
    switch (theme) {
      case ThemeType.pink:
        return PinkTheme.primary;
      case ThemeType.blue:
        return BlueTheme.primary;
      case ThemeType.purple:
        return PurpleTheme.primary;
      case ThemeType.green:
        return GreenTheme.primary;
      case ThemeType.yellow:
        return YellowTheme.primary;
    }
  }

  /// 获取当前主题渐变色
  static List<Color> get gradientColors {
    return gradientColorsFor(_currentTheme);
  }

  static List<Color> gradientColorsFor(ThemeType theme) {
    switch (theme) {
      case ThemeType.pink:
        return PinkTheme.gradientColors;
      case ThemeType.blue:
        return BlueTheme.gradientColors;
      case ThemeType.purple:
        return PurpleTheme.gradientColors;
      case ThemeType.green:
        return GreenTheme.gradientColors;
      case ThemeType.yellow:
        return YellowTheme.gradientColors;
    }
  }

  static ThemeType fromStorageValue(String value) {
    switch (value) {
      case 'blue':
        return ThemeType.blue;
      case 'lavender':
      case 'purple':
        return ThemeType.purple;
      case 'mint':
      case 'green':
        return ThemeType.green;
      case 'yellow':
        return ThemeType.yellow;
      case 'pink':
      default:
        return ThemeType.pink;
    }
  }

  static String toStorageValue(ThemeType theme) {
    switch (theme) {
      case ThemeType.pink:
        return 'pink';
      case ThemeType.blue:
        return 'blue';
      case ThemeType.purple:
        return 'purple';
      case ThemeType.green:
        return 'green';
      case ThemeType.yellow:
        return 'yellow';
    }
  }

  /// 获取主题名称
  static String getThemeName(ThemeType type) {
    switch (type) {
      case ThemeType.pink:
        return '樱花粉';
      case ThemeType.blue:
        return '天空蓝';
      case ThemeType.purple:
        return '薰衣草';
      case ThemeType.green:
        return '薄荷绿';
      case ThemeType.yellow:
        return '奶油黄';
    }
  }

  /// 获取主题预览颜色
  static Color getThemePreviewColor(ThemeType type) {
    switch (type) {
      case ThemeType.pink:
        return PinkTheme.primary;
      case ThemeType.blue:
        return BlueTheme.primary;
      case ThemeType.purple:
        return PurpleTheme.primary;
      case ThemeType.green:
        return GreenTheme.primary;
      case ThemeType.yellow:
        return YellowTheme.primary;
    }
  }

  /// 所有主题列表
  static List<ThemeType> get allThemes => ThemeType.values;

  /// 获取主题预览颜色列表
  static List<Color> get allPreviewColors {
    return ThemeType.values.map((e) => getThemePreviewColor(e)).toList();
  }
}
