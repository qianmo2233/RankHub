import 'package:rank_hub/core/account.dart';
import 'package:rank_hub/core/game_id.dart';
import 'package:rank_hub/core/platform_adapter_provider.dart';
import 'package:rank_hub/core/platform_id.dart';
import 'package:rank_hub/core/resource_key.dart';
import 'package:rank_hub/games/maimai/models/maimai_song.dart';
import 'package:rank_hub/games/maimai/models/maimai_score.dart';
import 'package:rank_hub/games/maimai/maimai_resources.dart';
import 'package:rank_hub/platform/lxns/lxns_api_service.dart';

/// 落雪咖啡屋平台适配器
/// 为 MaimaiDX 游戏提供数据资源
class LxnsPlatformAdapter extends BasePlatformAdapter {
  static const GameId maimaiDxGameId = GameId(
    name: 'maimai',
    version: 'DX',
    platform: 'arcade',
    region: 'CN',
  );

  late final LxnsApiService _apiService;

  LxnsPlatformAdapter({LxnsApiService? apiService})
    : super(id: const PlatformId('lxns'), supportedGames: [maimaiDxGameId]) {
    _apiService = apiService ?? LxnsApiService();
  }

  @override
  Future<T?> fetchResourceImpl<T>(ResourceKey key, Account account) async {
    try {
      // 根据资源键获取相应的资源
      if (key == maimaiSongListResourceKey) {
        return await _fetchSongList() as T?;
      } else if (key == maimaiScoreListResourceKey) {
        // 玩家成绩需要登录
        final accessToken = account.credentials['accessToken'] as String?;
        if (accessToken == null || accessToken.isEmpty) {
          throw LxnsApiException(message: '缺少访问令牌，请重新登录', code: 401);
        }
        return await _fetchScoreList(accessToken) as T?;
      } else if (key == maimaiVersionListResourceKey) {
        return await _fetchVersionList() as T?;
      } else if (key == maimaiGenreListResourceKey) {
        return await _fetchGenreList() as T?;
      }

      // 不支持的资源键
      return null;
    } catch (e) {
      print('❌ 获取资源失败 [${key.fullKey}]: $e');
      rethrow;
    }
  }

  /// 获取曲目列表（无需登录）
  Future<List<MaimaiSong>> _fetchSongList() async {
    print('📥 正在获取曲目列表...');
    final result = await _apiService.getSongList(notes: true);

    // 解析曲目列表
    final songsJson = result['songs'] as List;
    final songs = songsJson
        .map((e) => MaimaiSong.fromJson(e as Map<String, dynamic>))
        .toList();

    print('✅ 获取到 ${songs.length} 首曲目');
    return songs;
  }

  /// 获取成绩列表
  Future<List<MaimaiScore>> _fetchScoreList(String accessToken) async {
    print('📥 正在获取玩家成绩...');
    final scoresJson = await _apiService.getPlayerScores(
      accessToken: accessToken,
    );

    // 解析成绩列表
    final scores = scoresJson
        .map((e) => MaimaiScore.fromJson(e as Map<String, dynamic>))
        .toList();

    print('✅ 获取到 ${scores.length} 条成绩');
    return scores;
  }

  /// 获取版本列表（无需登录）
  Future<List<MaimaiVersion>> _fetchVersionList() async {
    print('📥 正在获取版本列表...');
    final result = await _apiService.getSongList(notes: false);

    // 解析版本列表
    final versionsJson = result['versions'] as List;
    final versions = versionsJson
        .map(
          (e) => MaimaiVersion(
            id: e['id'] as int,
            version: e['version'] as int,
            title: e['title'] as String,
          ),
        )
        .toList();

    print('✅ 获取到 ${versions.length} 个版本');
    return versions;
  }

  /// 获取曲风列表（无需登录）
  Future<List<MaimaiGenre>> _fetchGenreList() async {
    print('📥 正在获取曲风列表...');
    final result = await _apiService.getSongList(notes: false);

    // 解析曲风列表
    final genresJson = result['genres'] as List;
    final genres = genresJson
        .map(
          (e) => MaimaiGenre(id: e['id'] as int, genre: e['genre'] as String),
        )
        .toList();

    print('✅ 获取到 ${genres.length} 个曲风');
    return genres;
  }
}
