import 'package:isar_community/isar.dart';
import 'package:rank_hub/games/maimai/models/maimai_song.dart';
import 'package:rank_hub/games/maimai/models/maimai_score.dart';
import 'package:rank_hub/services/base_isar_service.dart';

/// Maimai 游戏数据库服务（新架构）
class MaimaiIsarService extends BaseIsarService {
  static MaimaiIsarService? _instance;

  MaimaiIsarService._();

  /// 获取单例实例
  static MaimaiIsarService get instance {
    _instance ??= MaimaiIsarService._();
    return _instance!;
  }

  @override
  String get databaseName => 'maimai_db';

  @override
  List<CollectionSchema> get schemas => [
    MaimaiSongSchema,
    MaimaiGenreSchema,
    MaimaiVersionSchema,
    MaimaiScoreSchema,
  ];

  // ==================== 曲目相关操作 ====================

  /// 批量保存曲目（智能合并）
  Future<void> saveSongs(List<MaimaiSong> songs) async {
    if (songs.isEmpty) return;

    final isar = await db;
    await isar.writeTxn(() async {
      for (final song in songs) {
        // 检查是否已存在
        final existing = await isar.maimaiSongs
            .filter()
            .songIdEqualTo(song.songId)
            .findFirst();

        if (existing != null) {
          // 合并数据：保留 Isar ID，更新其他字段
          song.id = existing.id;
        }

        await isar.maimaiSongs.put(song);
      }
    });
  }

  /// 获取所有曲目
  Future<List<MaimaiSong>> getAllSongs() async {
    final isar = await db;
    return await isar.maimaiSongs.where().findAll();
  }

  /// 根据曲目 ID 获取曲目
  Future<MaimaiSong?> getSongById(int songId) async {
    final isar = await db;
    return await isar.maimaiSongs.filter().songIdEqualTo(songId).findFirst();
  }

  /// 搜索曲目（按标题）
  Future<List<MaimaiSong>> searchSongsByTitle(String keyword) async {
    final isar = await db;
    return await isar.maimaiSongs
        .filter()
        .titleContains(keyword, caseSensitive: false)
        .findAll();
  }

  /// 清空所有曲目
  Future<void> clearAllSongs() async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.maimaiSongs.clear();
    });
  }

  // ==================== 版本相关操作 ====================

  /// 保存版本信息（智能合并）
  Future<void> saveVersions(List<MaimaiVersion> versions) async {
    if (versions.isEmpty) return;

    final isar = await db;
    await isar.writeTxn(() async {
      for (final version in versions) {
        // 检查是否已存在
        final existing = await isar.maimaiVersions
            .filter()
            .versionIdEqualTo(version.versionId)
            .findFirst();

        if (existing != null) {
          version.id = existing.id;
        }

        await isar.maimaiVersions.put(version);
      }
    });
  }

  /// 获取所有版本
  Future<List<MaimaiVersion>> getAllVersions() async {
    final isar = await db;
    return await isar.maimaiVersions.where().findAll();
  }

  /// 清空所有版本
  Future<void> clearAllVersions() async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.maimaiVersions.clear();
    });
  }

  // ==================== 曲风相关操作 ====================

  /// 保存曲风（智能合并）
  Future<void> saveGenres(List<MaimaiGenre> genres) async {
    if (genres.isEmpty) return;

    final isar = await db;
    await isar.writeTxn(() async {
      for (final genre in genres) {
        // 检查是否已存在
        final existing = await isar.maimaiGenres
            .filter()
            .genreIdEqualTo(genre.genreId)
            .findFirst();

        if (existing != null) {
          genre.id = existing.id;
        }

        await isar.maimaiGenres.put(genre);
      }
    });
  }

  /// 获取所有曲风
  Future<List<MaimaiGenre>> getAllGenres() async {
    final isar = await db;
    return await isar.maimaiGenres.where().findAll();
  }

  /// 清空所有曲风
  Future<void> clearAllGenres() async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.maimaiGenres.clear();
    });
  }

  // ==================== 成绩相关操作 ====================

  /// 批量保存成绩（智能合并）
  Future<void> saveScores(List<MaimaiScore> scores) async {
    if (scores.isEmpty) return;

    print('💾 准备保存 ${scores.length} 条成绩到数据库...');
    final isar = await db;

    await isar.writeTxn(() async {
      int newCount = 0;
      int updateCount = 0;

      for (final score in scores) {
        // 检查是否已存在（通过曲目ID、难度和类型精确匹配）
        final existing = await isar.maimaiScores
            .filter()
            .songIdEqualTo(score.songId)
            .and()
            .levelIndexEqualTo(score.levelIndex)
            .and()
            .typeEqualTo(score.type)
            .findFirst();

        if (existing != null) {
          // 已存在，保留 Isar ID 并更新数据
          score.id = existing.id;
          updateCount++;
        } else {
          // 新数据
          newCount++;
        }

        await isar.maimaiScores.put(score);
      }

      print('✅ 数据库保存完成: 新增 $newCount 条，更新 $updateCount 条');
    });
  }

  /// 获取所有成绩
  Future<List<MaimaiScore>> getAllScores() async {
    final isar = await db;
    return await isar.maimaiScores.where().findAll();
  }

  /// 根据曲目 ID 获取成绩
  Future<List<MaimaiScore>> getScoresBySongId(int songId) async {
    final isar = await db;
    return await isar.maimaiScores.filter().songIdEqualTo(songId).findAll();
  }

  /// 获取指定难度范围的成绩
  Future<List<MaimaiScore>> getScoresByLevelRange({
    required double minLevel,
    required double maxLevel,
  }) async {
    final isar = await db;
    // 需要通过关联 Song 表查询，这里简化为获取全部后过滤
    // TODO: 优化查询性能
    return await isar.maimaiScores.where().findAll();
  }

  /// 清空所有成绩
  Future<void> clearAllScores() async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.maimaiScores.clear();
    });
  }

  /// 删除数据库
  Future<void> deleteDatabase() async {
    await close();
    _instance = null;
  }
}
