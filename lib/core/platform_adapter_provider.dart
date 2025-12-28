import 'package:rank_hub/core/account.dart';
import 'package:rank_hub/core/game_id.dart';
import 'package:rank_hub/core/platform_adapter.dart';
import 'package:rank_hub/core/platform_id.dart';
import 'package:rank_hub/core/resource_key.dart';

/// 平台适配器基础实现
/// 提供通用的平台适配逻辑
abstract class BasePlatformAdapter implements PlatformAdapter {
  @override
  final PlatformId id;

  /// 支持的游戏ID列表
  final List<GameId> supportedGames;

  BasePlatformAdapter({required this.id, required this.supportedGames});

  @override
  bool supports(GameId gameId) {
    return supportedGames.any((game) => game.value == gameId.value);
  }

  @override
  Future<T?> fetchResource<T>(ResourceKey key, Account account) async {
    // 调用具体的资源获取逻辑
    return await fetchResourceImpl<T>(key, account);
  }

  /// 具体的资源获取实现（子类需实现）
  Future<T?> fetchResourceImpl<T>(ResourceKey key, Account account);
}

/// 平台适配器注册表
/// 管理所有平台适配器实例
class PlatformAdapterRegistry {
  final Map<String, PlatformAdapter> _adapters = {};

  /// 注册适配器
  void registerAdapter(PlatformAdapter adapter) {
    final key = adapter.id.value;
    if (_adapters.containsKey(key)) {
      throw Exception('Adapter already registered: $key');
    }
    _adapters[key] = adapter;
  }

  /// 批量注册适配器
  void registerAdapters(List<PlatformAdapter> adapters) {
    for (final adapter in adapters) {
      registerAdapter(adapter);
    }
  }

  /// 根据平台ID查找适配器
  PlatformAdapter? findById(PlatformId id) {
    return _adapters[id.value];
  }

  /// 根据ID字符串查找适配器
  PlatformAdapter? findByIdString(String id) {
    return _adapters[id];
  }

  /// 查找支持指定游戏的所有适配器
  List<PlatformAdapter> findByGameId(GameId gameId) {
    return _adapters.values
        .where((adapter) => adapter.supports(gameId))
        .toList();
  }

  /// 检查适配器是否已注册
  bool hasAdapter(PlatformId id) {
    return _adapters.containsKey(id.value);
  }

  /// 获取所有适配器
  List<PlatformAdapter> getAllAdapters() {
    return _adapters.values.toList();
  }

  /// 获取所有适配器ID
  List<PlatformId> getAllAdapterIds() {
    return _adapters.keys.map((id) => PlatformId(id)).toList();
  }

  /// 移除适配器
  void unregisterAdapter(PlatformId id) {
    _adapters.remove(id.value);
  }

  /// 清空所有适配器
  void clear() {
    _adapters.clear();
  }

  /// 获取适配器数量
  int get adapterCount => _adapters.length;

  /// 检查是否为空
  bool get isEmpty => _adapters.isEmpty;

  /// 检查是否非空
  bool get isNotEmpty => _adapters.isNotEmpty;

  /// 获取游戏支持映射（游戏ID -> 支持的平台列表）
  Map<String, List<String>> getGameSupportMatrix() {
    final matrix = <String, List<String>>{};

    for (final adapter in _adapters.values) {
      // 需要子类提供支持的游戏列表
      if (adapter is BasePlatformAdapter) {
        for (final gameId in adapter.supportedGames) {
          matrix.putIfAbsent(gameId.value, () => []).add(adapter.id.value);
        }
      }
    }

    return matrix;
  }
}
