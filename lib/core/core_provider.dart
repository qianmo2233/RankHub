import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rank_hub/core/account.dart';
import 'package:rank_hub/core/core_context.dart';
import 'package:rank_hub/core/credential_provider.dart';
import 'package:rank_hub/core/game.dart';
import 'package:rank_hub/core/game_registry_provider.dart';
import 'package:rank_hub/core/login_provider.dart';
import 'package:rank_hub/core/platform.dart';
import 'package:rank_hub/core/platform_adapter_provider.dart';
import 'package:rank_hub/core/platform_game_registry.dart';
import 'package:rank_hub/core/platform_id.dart';
import 'package:rank_hub/core/platform_registry_provider.dart';
import 'package:rank_hub/core/resource_loader.dart';
import 'package:rank_hub/core/resource_registry_provider.dart';
import 'package:rank_hub/core/services/storage_service.dart';

class CoreProvider {
  // 单例模式
  static CoreProvider? _instance;

  CoreProvider._();

  /// 获取单例实例
  static CoreProvider get instance {
    _instance ??= CoreProvider._();
    return _instance!;
  }

  // ==================== 注册表 ====================

  /// 平台注册表
  final PlatformRegistryProvider platformRegistry = PlatformRegistryProvider();

  /// 游戏注册表
  final GameRegistryProvider gameRegistry = GameRegistryProvider();

  /// 平台-游戏关联注册表
  final PlatformGameRegistry platformGameRegistry = PlatformGameRegistry();

  /// 资源注册表
  final ResourceRegistryProvider resourceRegistry = ResourceRegistryProvider();

  /// 平台适配器注册表
  final PlatformAdapterRegistry adapterRegistry = PlatformAdapterRegistry();

  // ==================== 服务 ====================

  /// 存储服务
  final CoreStorageService coreStorage = CoreStorageService.instance;

  // ==================== 凭据和登录提供者映射 ====================

  final Map<String, CredentialProvider> _credentialProviders = {};
  final Map<String, PlatformLoginHandler> _loginHandlers = {};

  // ==================== 注册方法 ====================

  /// 注册凭据提供者
  void registerCredentialProvider(CredentialProvider provider) {
    _credentialProviders[provider.platformId.value] = provider;
  }

  /// 注册登录处理器
  void registerLoginHandler(PlatformLoginHandler handler) {
    _loginHandlers[handler.platformId.value] = handler;
  }

  /// 批量注册凭据提供者
  void registerCredentialProviders(List<CredentialProvider> providers) {
    for (final provider in providers) {
      registerCredentialProvider(provider);
    }
  }

  /// 批量注册登录处理器
  void registerLoginHandlers(List<PlatformLoginHandler> handlers) {
    for (final handler in handlers) {
      registerLoginHandler(handler);
    }
  }

  // ==================== 获取方法 ====================

  /// 获取凭据提供者
  CredentialProvider? getCredentialProvider(String platformId) {
    return _credentialProviders[platformId];
  }

  /// 获取登录处理器
  PlatformLoginHandler? getLoginHandler(String platformId) {
    return _loginHandlers[platformId];
  }

  /// 获取所有凭据提供者
  List<CredentialProvider> getAllCredentialProviders() {
    return _credentialProviders.values.toList();
  }

  /// 获取所有登录处理器
  List<PlatformLoginHandler> getAllLoginHandlers() {
    return _loginHandlers.values.toList();
  }

  // ==================== 平台-游戏关联便捷方法 ====================

  /// 获取平台支持的所有游戏
  ///
  /// [platformId] 平台ID字符串
  List<Game> getGamesByPlatform(String platformId) {
    final gameIdStrings = platformGameRegistry.getGamesForPlatform(
      PlatformId(platformId),
    );
    return gameRegistry.getGamesByIdStrings(gameIdStrings);
  }

  /// 获取支持某个游戏的所有平台
  ///
  /// [gameIdString] 游戏ID字符串
  List<Platform> getPlatformsForGame(String gameIdString) {
    // 先找到游戏对象以获取完整的 GameId
    final game = gameRegistry.findByIdString(gameIdString);
    if (game == null) return [];

    final platformIdStrings = platformGameRegistry.getPlatformsForGame(game.id);
    return platformIdStrings
        .map((id) => platformRegistry.findByIdString(id))
        .whereType<Platform>()
        .toList();
  }

  /// 检查平台是否支持某个游戏
  ///
  /// [platformId] 平台ID字符串
  /// [gameIdString] 游戏ID字符串
  bool isPlatformSupportGame(String platformId, String gameIdString) {
    final game = gameRegistry.findByIdString(gameIdString);
    if (game == null) return false;

    return platformGameRegistry.isPlatformSupportGame(
      PlatformId(platformId),
      game.id,
    );
  }

  // ==================== 初始化和清理 ====================

  /// 初始化服务提供者
  Future<void> initialize() async {
    // 初始化存储服务
    await coreStorage.initialize();
  }

  /// 清理所有服务
  Future<void> dispose() async {
    platformRegistry.clear();
    gameRegistry.clear();
    platformGameRegistry.clear();
    resourceRegistry.clear();
    adapterRegistry.clear();
    _credentialProviders.clear();
    _loginHandlers.clear();

    // 关闭存储服务
    await coreStorage.close();
  }

  // ==================== 上下文管理副作用方法 ====================

  /// 设置当前游戏
  /// 会自动保存选择并更新上下文
  Future<void> setCurrentGame(Game game, Ref ref) async {
    try {
      // 保存游戏选择
      await coreStorage.setLastSelectedGameId(game.id.value);

      // 加载该游戏对应的账号
      final account = await coreStorage.getSelectedAccount(game.id.value);

      // 重建 AppContext
      if (account != null) {
        await _buildAppContext(game, account, ref);
      } else {
        // 游客模式 - 构建没有账号的 AppContext
        await _buildGuestAppContext(game, ref);
      }
    } catch (e) {
      print('⚠️ 设置当前游戏失败: $e');
      rethrow;
    }
  }

  /// 设置当前账号
  /// 会自动检查账号与游戏的匹配，必要时切换游戏
  Future<void> setCurrentAccount(Account account, Ref ref) async {
    try {
      final currentContext = ref.read(appContextProvider);
      final currentGame = currentContext?.game;

      // 检查账号是否与当前游戏匹配
      if (currentGame != null) {
        final isCompatible = await _checkAccountGameCompatibility(
          account,
          currentGame,
        );

        if (!isCompatible) {
          // 账号与当前游戏不匹配，需要切换游戏
          await _switchToCompatibleGame(account, ref);
          return;
        }
      }

      // 账号与游戏匹配，重建 Context
      if (currentGame != null) {
        await coreStorage.setSelectedAccountForGame(
          currentGame.id.value,
          account.platformId,
          _getAccountIdentifier(account),
        );

        // 重建 AppContext（账号切换）
        await _buildAppContext(currentGame, account, ref);
      }
    } catch (e) {
      print('⚠️ 设置当前账号失败: $e');
      rethrow;
    }
  }

  /// 检查账号与游戏的兼容性
  Future<bool> _checkAccountGameCompatibility(
    Account account,
    Game game,
  ) async {
    // 获取支持该游戏的所有平台
    final supportedPlatforms = platformGameRegistry.getPlatformsForGame(
      game.id,
    );

    // 检查账号的平台是否在支持列表中
    final isCompatible = supportedPlatforms.any(
      (platformId) => platformId == account.platformId,
    );

    if (!isCompatible) {
      print('账号平台 ${account.platformId} 不支持游戏 ${game.id.value}');
      print('   支持的平台: ${supportedPlatforms.join(", ")}');
    }

    return isCompatible;
  }

  /// 切换到与账号兼容的游戏
  Future<void> _switchToCompatibleGame(Account account, Ref ref) async {
    try {
      // 1. 尝试从历史记录中获取该账号最后使用的游戏
      final accountId = _getAccountIdentifier(account);
      final lastGameId = await _getLastGameForAccount(
        account.platformId,
        accountId,
      );

      Game? targetGame;

      if (lastGameId != null) {
        // 查找对应的游戏
        final allGames = gameRegistry.getAllGames();
        try {
          targetGame = allGames.firstWhere((g) => g.id.value == lastGameId);
        } catch (e) {
          // 历史游戏不存在
        }
      }

      // 2. 如果没有历史记录或历史游戏不存在，选择第一个兼容的游戏
      targetGame ??= await _findFirstCompatibleGame(account);

      // 3. 切换到目标游戏
      if (targetGame != null) {
        await setCurrentGame(targetGame, ref);

        // 保存账号选择
        await coreStorage.setSelectedAccountForGame(
          targetGame.id.value,
          account.platformId,
          accountId,
        );

        // 重建 AppContext
        await _buildAppContext(targetGame, account, ref);
      } else {
        print('⚠️ 没有找到与账号兼容的游戏');
      }
    } catch (e) {
      print('⚠️ 切换兼容游戏失败: $e');
      rethrow;
    }
  }

  /// 查找第一个与账号兼容的游戏
  Future<Game?> _findFirstCompatibleGame(Account account) async {
    final allGames = gameRegistry.getAllGames();

    for (final game in allGames) {
      if (await _checkAccountGameCompatibility(account, game)) {
        return game;
      }
    }

    return allGames.isNotEmpty ? allGames.first : null;
  }

  /// 获取账号最后使用的游戏ID
  Future<String?> _getLastGameForAccount(
    String platformId,
    String accountId,
  ) async {
    // 从存储的元数据中获取
    // 可以扩展 AccountEntity 来存储最后使用的游戏ID
    // 目前返回null，表示没有历史记录
    return null;
  }

  /// 构建应用上下文（完全重建 Scope + Loader）
  Future<void> _buildAppContext(Game game, Account account, Ref ref) async {
    try {
      final adapters = adapterRegistry.getAllAdapters();

      ref
          .read(appContextProvider.notifier)
          .buildContext(
            game: game,
            account: account,
            adapters: adapters,
            loaderFactory: (scope, adapters) => ResourceLoader(
              registry: resourceRegistry,
              scope: scope,
              adapters: adapters,
            ),
          );

      print(
        '✨ 已重建 AppContext: ${game.id.value}, account: ${_getAccountIdentifier(account)}',
      );
    } catch (e) {
      print('⚠️ 构建应用上下文失败: $e');
    }
  }

  /// 构建游客模式的应用上下文（无账号）
  Future<void> _buildGuestAppContext(Game game, Ref ref) async {
    try {
      final adapters = adapterRegistry.getAllAdapters();

      ref
          .read(appContextProvider.notifier)
          .buildContext(
            game: game,
            account: null,
            adapters: adapters,
            loaderFactory: (scope, adapters) => ResourceLoader(
              registry: resourceRegistry,
              scope: scope,
              adapters: adapters,
            ),
          );

      print('✨ 已重建 AppContext（游客模式）: ${game.id.value}');
    } catch (e) {
      print('⚠️ 构建游客模式应用上下文失败: $e');
    }
  }

  /// 从账号中提取标识符
  String _getAccountIdentifier(Account account) {
    // 从凭证中提取账号标识符
    // 不同平台可能有不同的标识字段
    return account.credentials['external_id']?.toString() ??
        account.credentials['user_id']?.toString() ??
        account.credentials['username']?.toString() ??
        '';
  }

  // ==================== 统计信息 ====================

  /// 获取服务统计信息
  Map<String, dynamic> getStats() {
    return {
      'platforms': platformRegistry.platformCount,
      'games': gameRegistry.gameCount,
      'resources': resourceRegistry.getStats(),
      'adapters': adapterRegistry.adapterCount,
      'credential_providers': _credentialProviders.length,
      'login_handlers': _loginHandlers.length,
    };
  }

  /// 打印服务统计信息
  void printStats() {
    final stats = getStats();
    print('=== Core Provider Stats ===');
    print('Platforms: ${stats['platforms']}');
    print('Games: ${stats['games']}');
    print('Resources: ${stats['resources']}');
    print('Adapters: ${stats['adapters']}');
    print('Credential Providers: ${stats['credential_providers']}');
    print('Login Handlers: ${stats['login_handlers']}');
    print('===========================');
  }
}
