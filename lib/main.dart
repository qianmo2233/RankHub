import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:rank_hub/routes/app_pages.dart';
import 'package:rank_hub/routes/app_routes.dart';
import 'package:rank_hub/controllers/theme_controller.dart';
import 'package:rank_hub/services/log_service.dart';
import 'package:rank_hub/services/qr_code_scanner_service.dart';
import 'package:rank_hub/services/mai_party_qr_handler.dart';
import 'package:rank_hub/services/mai_net_qr_handler.dart';
import 'package:rank_hub/services/queue_status_manager.dart';
import 'package:rank_hub/services/live_activity_service.dart';
import 'package:rank_hub/core/core_provider.dart';
import 'package:rank_hub/games/maimai/maimai.dart';
import 'package:rank_hub/games/maimai/maimai_data_definitions.dart';
import 'package:rank_hub/platform/lxns/lxns_platform.dart';
import 'package:rank_hub/platform/lxns/lxns_platform_adapter.dart';
import 'package:x_amap_base/x_amap_base.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化日志服务
  final logService = LogService.instance;
  logService.initialize();

  // 初始化 Core 架构
  final coreProvider = CoreProvider.instance;
  await coreProvider.initialize();
  print('✅ Core 架构初始化完成');

  // 注册 Maimai 游戏
  final maimaiGame = Maimai();
  coreProvider.gameRegistry.registerGame(maimaiGame);
  print('✅ 注册游戏: ${maimaiGame.name}');

  // 注册 LXNS 平台
  final lxnsPlatform = LxnsPlatform();
  coreProvider.platformRegistry.registerPlatform(lxnsPlatform);
  print('✅ 注册平台: ${lxnsPlatform.name}');

  // 关联 LXNS 平台与 Maimai 游戏
  coreProvider.platformGameRegistry.associate(lxnsPlatform.id, maimaiGame.id);
  print('✅ 关联平台与游戏: ${lxnsPlatform.name} <-> ${maimaiGame.name}');

  // 注册 LXNS 平台适配器
  final lxnsAdapter = LxnsPlatformAdapter();
  coreProvider.adapterRegistry.registerAdapter(lxnsAdapter);
  print('✅ 注册平台适配器: LXNS');

  // 注册 Maimai 资源定义
  coreProvider.resourceRegistry.registerResources([
    MaimaiSongListResource(),
    MaimaiVersionListResource(),
    MaimaiGenreListResource(),
    MaimaiScoreListResource(),
  ]);
  print('✅ 注册 Maimai 资源定义: 曲目列表、版本列表、曲风列表、成绩列表');

  // 初始化 Live Activities
  await LiveActivityService.instance.init();

  // 注册二维码处理器
  final qrService = QRCodeScannerService();
  qrService.registerHandler(MaiPartyQRCodeHandler());
  qrService.registerHandler(MaiNetQRCodeHandler());

  // 初始化排队状态管理器
  Get.put(QueueStatusManager());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.put(ThemeController());

    AMapInitializer.updatePrivacyAgree(
      AMapPrivacyStatement(hasContains: true, hasShow: true, hasAgree: true),
    );

    AMapInitializer.init(
      context,
      apiKey: AMapApiKey(
        iosKey: '808f8cff67cf6e0af5d1718a9d3b6a6b',
        androidKey: '9d203d41e9a4e6f41f16845a56ccec81',
      ),
    );

    return Obx(
      () => ProviderScope(
        child: GetMaterialApp(
          title: 'RankHub',
          theme: themeController.getLightTheme(),
          darkTheme: themeController.getDarkTheme(),
          themeMode: themeController.themeMode.value,
          initialRoute: AppRoutes.main,
          getPages: AppPages.routes,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
