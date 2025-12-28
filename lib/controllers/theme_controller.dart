import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static const String _themeModeKey = 'theme_mode';
  static const String _seedColorKey = 'seed_color';

  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;
  final Rx<Color> seedColor = Colors.blue.obs;
  final RxBool forceUseDark = false.obs; // 强制使用暗色主题标志

  @override
  void onInit() {
    super.onInit();
    _loadThemeSettings();
  }

  /// 加载主题设置
  Future<void> _loadThemeSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 加载主题模式
    final themeModeIndex = prefs.getInt(_themeModeKey);
    if (themeModeIndex != null) {
      themeMode.value = ThemeMode.values[themeModeIndex];
    }

    // 加载主题色
    final colorValue = prefs.getInt(_seedColorKey);
    if (colorValue != null) {
      seedColor.value = Color(colorValue);
    }
  }

  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    if (!forceUseDark.value) {
      Get.changeThemeMode(mode);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  /// 强制使用暗色主题（用于特殊页面如社区页）
  void setForceUseDark(bool force) {
    forceUseDark.value = force;
    if (force) {
      Get.changeThemeMode(ThemeMode.dark);
    } else {
      Get.changeThemeMode(themeMode.value);
    }
  }

  /// 设置主题色
  Future<void> setSeedColor(Color color) async {
    seedColor.value = color;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seedColorKey, color.value);
  }

  /// 获取主题模式显示文本
  String getThemeModeText() {
    switch (themeMode.value) {
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  /// 获取亮色主题
  ThemeData getLightTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor.value,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }

  /// 获取暗色主题
  ThemeData getDarkTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor.value,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}
