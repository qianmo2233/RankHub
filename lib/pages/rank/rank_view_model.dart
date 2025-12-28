import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rank_hub/core/core_context.dart';
import 'package:rank_hub/core/core_provider.dart';
import 'package:rank_hub/core/game.dart';
import 'package:rank_hub/core/models/account_entity.dart';

/// Rank 页面的 Notifier
/// 使用 CoreContext 进行状态管理
class RankNotifier extends Notifier<void> {
  final CoreProvider _service = CoreProvider.instance;

  @override
  void build() {
    _initialize();
  }

  /// 初始化
  Future<void> _initialize() async {
    try {
      // 确保服务已初始化
      await _service.initialize();

      // 加载可用游戏列表
      final games = _service.gameRegistry.getAllGames();

      // 使用 core 服务加载游戏和账号，并自动更新 CoreContext
      final (selectedGame, account) = await _service.coreStorage
          .loadLastSelectedGameAndAccount(games);

      if (selectedGame != null) {
        // 通过 CoreProvider 的副作用方法设置游戏，会自动更新 CoreContext
        await _service.setCurrentGame(selectedGame, ref);
      }
    } catch (e) {
      print('初始化失败: $e');
    }
  }

  /// 选择游戏
  Future<void> selectGame(Game game) async {
    try {
      // 使用 CoreProvider 的副作用方法设置游戏
      // 会自动保存选择、加载账号并更新 CoreContext
      await _service.setCurrentGame(game, ref);
    } catch (e) {
      print('选择游戏失败: $e');
    }
  }

  /// 获取可用游戏列表
  List<Game> getAvailableGames() {
    return _service.gameRegistry.getAllGames();
  }

  // ==================== 账号管理方法 ====================

  /// 为当前游戏选择账号
  Future<void> selectAccountForCurrentGame(
    String platformId,
    String accountIdentifier,
  ) async {
    final appContext = ref.read(appContextProvider);
    final selectedGame = appContext?.game;
    if (selectedGame == null) return;

    try {
      // 保存游戏账号选择到存储
      await _service.coreStorage.setSelectedAccountForGame(
        selectedGame.id.value,
        platformId,
        accountIdentifier,
      );

      // 重新加载该游戏
      await selectGame(selectedGame);
    } catch (e) {
      print('⚠️ 选择账号失败: $e');
    }
  }

  /// 获取指定平台的所有账号
  Future<List<AccountEntity>> getAccountsForPlatform(String platformId) async {
    try {
      return await _service.coreStorage.getAccountEntitiesByPlatform(
        platformId,
      );
    } catch (e) {
      print('⚠️ 获取平台账号失败: $e');
      return [];
    }
  }

  /// 清除当前游戏的账号选择
  Future<void> clearAccountForCurrentGame() async {
    final appContext = ref.read(appContextProvider);
    final selectedGame = appContext?.game;
    if (selectedGame == null) return;

    try {
      await _service.coreStorage.clearSelectedAccountForGame(
        selectedGame.id.value,
      );

      // 清除账号，重新加载游戏
      await selectGame(selectedGame);
    } catch (e) {
      print('清除账号选择失败: $e');
    }
  }

  /// 刷新数据
  Future<void> refresh() async {
    final appContext = ref.read(appContextProvider);
    final selectedGame = appContext?.game;

    try {
      // 重新加载当前游戏
      if (selectedGame != null) {
        await selectGame(selectedGame);
      }
    } catch (e) {
      print('刷新失败: $e');
    }
  }
}

/// Rank Provider
final rankProvider = NotifierProvider<RankNotifier, void>(() {
  return RankNotifier();
});
