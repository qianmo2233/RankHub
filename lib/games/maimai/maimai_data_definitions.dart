import 'package:rank_hub/core/account.dart';
import 'package:rank_hub/core/data_definition.dart';
import 'package:rank_hub/core/platform_adapter.dart';
import 'package:rank_hub/core/resource_key.dart';
import 'package:rank_hub/core/resource_scope.dart';
import 'package:rank_hub/games/maimai/maimai_resources.dart';
import 'package:rank_hub/games/maimai/models/maimai_score.dart';
import 'package:rank_hub/games/maimai/models/maimai_song.dart';
import 'package:rank_hub/games/maimai/services/maimai_isar_service.dart';

/// Maimai 曲目列表资源定义
class MaimaiSongListResource extends GameResourceDefinition<List<MaimaiSong>> {
  @override
  ResourceKey<List<MaimaiSong>> get key => maimaiSongListResourceKey;

  @override
  Duration? get ttl => const Duration(days: 7); // 曲目列表缓存 7 天

  @override
  bool get accountRelated => false; // 曲目列表与账号无关

  @override
  Future<List<MaimaiSong>> fetch(
    ResourceScope scope,
    List<PlatformAdapter> adapters,
  ) async {
    // 首先尝试从数据库加载（如果未过期）
    try {
      final cachedSongs = await MaimaiIsarService.instance.getAllSongs();
      if (cachedSongs.isNotEmpty) {
        print('✅ 从数据库加载 ${cachedSongs.length} 首曲目（缓存）');
        return cachedSongs;
      }
    } catch (e) {
      print('⚠️ 从数据库加载失败: $e，将从网络获取');
    }

    // 找到支持该游戏的平台适配器
    final adapter = adapters.firstWhere(
      (a) => a.supports(scope.gameId),
      orElse: () => throw Exception('未找到支持 ${scope.gameId.value} 的平台适配器'),
    );

    // 曲目列表不需要登录，传空凭据的账号
    final account = Account(
      platformId: scope.platformId.value,
      credentials: {},
    );

    // 从平台适配器获取数据
    final songs = await adapter.fetchResource<List<MaimaiSong>>(key, account);
    return songs ?? [];
  }

  @override
  List<MaimaiSong>? loadCache() {
    // 尝试从数据库同步加载缓存
    // 注意：Isar 是异步的，这里可能返回 null
    // 在实际应用中，ResourceLoader 会在缓存未命中时调用 fetch
    try {
      // 由于 Isar 是异步的，这里无法同步获取数据
      // 返回 null，让系统通过 fetch 从网络或数据库异步加载
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> persist(List<MaimaiSong> data) async {
    // 持久化到 Isar 数据库
    await MaimaiIsarService.instance.saveSongs(data);
    print('✅ 已保存 ${data.length} 首曲目到数据库');
  }
}

/// Maimai 版本列表资源定义
class MaimaiVersionListResource
    extends GameResourceDefinition<List<MaimaiVersion>> {
  @override
  ResourceKey<List<MaimaiVersion>> get key => maimaiVersionListResourceKey;

  @override
  Duration? get ttl => const Duration(days: 7); // 版本列表缓存 7 天

  @override
  bool get accountRelated => false; // 版本列表与账号无关

  @override
  Future<List<MaimaiVersion>> fetch(
    ResourceScope scope,
    List<PlatformAdapter> adapters,
  ) async {
    final adapter = adapters.firstWhere(
      (a) => a.supports(scope.gameId),
      orElse: () => throw Exception('未找到支持 ${scope.gameId.value} 的平台适配器'),
    );

    final account = Account(
      platformId: scope.platformId.value,
      credentials: {},
    );

    final versions = await adapter.fetchResource<List<MaimaiVersion>>(
      key,
      account,
    );
    return versions ?? [];
  }

  @override
  List<MaimaiVersion>? loadCache() {
    // loadCache 是同步方法，但 Isar 是异步的
    return null;
  }

  @override
  Future<void> persist(List<MaimaiVersion> data) async {
    await MaimaiIsarService.instance.saveVersions(data);
    print('✅ 已保存 ${data.length} 个版本到数据库');
  }
}

/// Maimai 曲风列表资源定义
class MaimaiGenreListResource
    extends GameResourceDefinition<List<MaimaiGenre>> {
  @override
  ResourceKey<List<MaimaiGenre>> get key => maimaiGenreListResourceKey;

  @override
  Duration? get ttl => const Duration(days: 7); // 曲风列表缓存 7 天

  @override
  bool get accountRelated => false; // 曲风列表与账号无关

  @override
  Future<List<MaimaiGenre>> fetch(
    ResourceScope scope,
    List<PlatformAdapter> adapters,
  ) async {
    final adapter = adapters.firstWhere(
      (a) => a.supports(scope.gameId),
      orElse: () => throw Exception('未找到支持 ${scope.gameId.value} 的平台适配器'),
    );

    final account = Account(
      platformId: scope.platformId.value,
      credentials: {},
    );

    final genres = await adapter.fetchResource<List<MaimaiGenre>>(key, account);
    return genres ?? [];
  }

  @override
  List<MaimaiGenre>? loadCache() {
    // loadCache 是同步方法，但 Isar 是异步的
    return null;
  }

  @override
  Future<void> persist(List<MaimaiGenre> data) async {
    await MaimaiIsarService.instance.saveGenres(data);
    print('✅ 已保存 ${data.length} 个曲风到数据库');
  }
}

/// Maimai 成绩列表资源定义
class MaimaiScoreListResource
    extends GameResourceDefinition<List<MaimaiScore>> {
  @override
  ResourceKey<List<MaimaiScore>> get key => maimaiScoreListResourceKey;

  @override
  Duration? get ttl => const Duration(hours: 1); // 成绩列表缓存 1 小时

  @override
  bool get accountRelated => true; // 成绩列表与账号相关

  @override
  bool get forceRefreshWhenTriggered => true; // 刷新时强制重新拉取

  @override
  Future<List<MaimaiScore>> fetch(
    ResourceScope scope,
    List<PlatformAdapter> adapters,
  ) async {
    if (!scope.hasAccount) {
      throw Exception('成绩列表需要登录账号');
    }

    // 从 AccountRegistry 获取账号
    final account = AccountRegistry.instance.get(scope.accountIdentifier!);
    if (account == null) {
      throw Exception(
        '未找到账号: ${scope.accountIdentifier}，请确保账号已注册到 AccountRegistry',
      );
    }

    // 验证有支持该游戏的适配器
    final adapter = adapters.firstWhere(
      (a) => a.supports(scope.gameId),
      orElse: () => throw Exception('未找到支持 ${scope.gameId.value} 的平台适配器'),
    );

    // 从适配器获取成绩数据
    final scores = await adapter.fetchResource<List<MaimaiScore>>(key, account);
    return scores ?? [];
  }

  @override
  List<MaimaiScore>? loadCache() {
    // loadCache 是同步方法，但 Isar 是异步的
    return null;
  }

  @override
  Future<void> persist(List<MaimaiScore> data) async {
    await MaimaiIsarService.instance.saveScores(data);
    // saveScores 已经包含了打印日志
  }
}
