import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:rank_hub/controllers/theme_controller.dart';

/// Main 页面的 ViewModel
/// 管理底部导航栏的当前索引
class MainNotifier extends Notifier<int> {
  @override
  int build() {
    // 初始索引为 0（社区页）
    // 初始化时也要设置主题
    Future.microtask(() {
      final themeController = Get.find<ThemeController>();
      themeController.setForceUseDark(true);
    });
    return 0;
  }

  /// 切换底部导航标签
  void changeTabIndex(int index) {
    state = index;

    // 根据索引控制主题
    final themeController = Get.find<ThemeController>();
    if (index == 0) {
      // 社区页，强制使用暗色主题
      themeController.setForceUseDark(true);
    } else {
      // 其他页面，恢复正常主题
      themeController.setForceUseDark(false);
    }
  }
}

/// Main Provider
final mainProvider = NotifierProvider<MainNotifier, int>(() {
  return MainNotifier();
});
