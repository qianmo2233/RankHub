import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rank_hub/src/model/mai_song_filter_data.dart';
import 'package:rank_hub/src/model/mai_types.dart';
import 'package:rank_hub/src/model/maimai/player_data.dart';
import 'package:rank_hub/src/model/maimai/song_difficulty.dart';
import 'package:rank_hub/src/model/maimai/song_info.dart';
import 'package:rank_hub/src/model/maimai/song_score.dart';
import 'package:rank_hub/src/pages/add_lx_mai_screen.dart';
import 'package:rank_hub/src/view/maimai/lx_rank_page_view.dart';
import 'package:rank_hub/src/view/maimai/lx_wiki_page.dart';
import 'package:rank_hub/src/view/maimai/song_detail_screen.dart';
import 'package:rank_hub/src/provider/data_source_provider.dart';
import 'package:rank_hub/src/view/maimai/lx_song_card.dart';
import 'package:rank_hub/src/provider/player_manager.dart';
import 'package:rank_hub/src/services/lx_api_services.dart';
import 'package:rank_hub/src/view/maimai/lx_mai_record_card.dart';

class LxMaiProvider extends DataSourceProvider<SongScore, PlayerData, SongInfo,
    MaiSongFilterData> {
  late PlayerManager _playerManager;
  late LxApiService _lxApiService;

  LxApiService get lxApiService => _lxApiService;

  LxMaiProvider({required BuildContext context}) {
    _playerManager = Provider.of<PlayerManager>(context, listen: false);
    _lxApiService = LxApiService(_playerManager, this);

    lxApiService.getAllPlayerUUID().then((players) => {
          for (String playerUUID in players)
            {_playerManager.addPlayer(playerUUID, getProviderName())}
        });
  }
  @override
  Future<PlayerData> addPlayer(String? token) async {
    final apiKey = token!.trim();

    if (apiKey.isEmpty) {
      throw Exception('请输入有效的 API 密钥');
    }

    try {
      // 调用 API 服务
      final player = await _lxApiService.addPlayer(apiKey);

      return player;
    } on DioException catch (e) {
      // 根据响应码处理错误
      String errorMessage;
      if (e.response != null) {
        switch (e.response?.statusCode) {
          case 401:
            errorMessage = '身份验证失败，请检查 API 密钥是否正确';
            break;
          case 500:
            errorMessage = '服务器内部错误，请稍后重试';
            break;
          default:
            errorMessage = '请求失败，错误码：${e.response?.statusCode}';
        }
      } else {
        // 网络问题或其他错误
        errorMessage = '无法连接到服务器，请检查网络';
      }
      throw Exception(errorMessage);
    } on Exception catch (e) {
      // 根据异常类型判断是否是重复添加
      final errorMessage = e.toString().contains('该玩家已存在')
          ? '该玩家已存在，不能重复添加'
          : '添加失败：${e.toString()}';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('发生未知错误：${e.toString()}');
    }
  }

  @override
  Widget buildAddPlayerScreen() {
    return AddLxMaiScreen(provider: this);
  }

  @override
  Widget buildOverviewCard() {
    // TODO: implement buildOverviewCard
    throw UnimplementedError();
  }

  @override
  Widget buildPlayerDetailScreen(PlayerData playerData) {
    // TODO: implement buildPlayerDetailScreen
    throw UnimplementedError();
  }

  @override
  Widget buildProviderIcon() {
    return CachedNetworkImage(
      imageUrl: 'https://maimai.lxns.net/favicon.webp',
      width: 36,
      height: 36,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 500), // Fade-in duration
      placeholder: (context, url) => Transform.scale(
        scale: 0.4,
        child: const CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => const Icon(
        Icons.image_not_supported,
        size: 16,
      ),
    );
  }

  @override
  Widget buildRankedRecordList() {
    // TODO: implement buildRankedRecordList
    throw UnimplementedError();
  }

  @override
  Widget buildRecordCard(SongScore recordData) {
    return LxMaiRecordCard(recordData: recordData);
  }

  @override
  Widget buildRecordList() {
    return const MaiRankPage();
  }

  @override
  Widget buildSongCard(SongInfo songData) {
    return LxMaiSongCard(songData: songData, provider: this);
  }

  @override
  Widget buildSongDetailScreen(SongInfo songData) {
    return SongDetailScreen(song: songData);
  }

  @override
  Widget buildSongList() {
    return const WikiPage();
  }

  @override
  Future<void> deletePlayer() {
    // TODO: implement deletePlayer
    throw UnimplementedError();
  }

  @override
  Future<List<SongInfo>> getAllSongs({bool forceRefresh = false}) async {
    return await _lxApiService.getSongList(forceRefresh: forceRefresh);
  }

  @override
  Future<PlayerData> getPlayerDetail() {
    // TODO: implement getPlayerDetail
    throw UnimplementedError();
  }

  @override
  String getProviderGameName() {
    return '舞萌 DX';
  }

  @override
  String getProviderLoacation() {
    return "maimai.lxns.net";
  }

  @override
  String getProviderName() {
    return 'LxMai';
  }

  @override
  Future<Map<String, List<SongScore>>> getRankedRecords() async {
    return {
      'B15': await lxApiService.getB15Records(),
      'B35': await lxApiService.getB35Records(),
    };
  }

  @override
  Future<List<SongScore>> getRecords({bool forceRefresh = false, String? uuid}) {
    return lxApiService.getRecordList(forceRefresh: forceRefresh, uuid: uuid);
  }

  @override
  Future<SongInfo> getSongDetail() {
    // TODO: implement getSongDetail
    throw UnimplementedError();
  }

  @override
  Future<List<SongScore>> filterRecords(MaiSongFilterData filterData) async {
    // Pre-fetch data
    final songs = await getAllSongs();
    final records = await getRecords();

    // Return early if no filters are applied
    if (filterData.areAllValuesNull) {
      return records;
    }

    // Convert filter data into efficient lookup sets/maps
    final levelIndexSet = filterData.levelIndex?.map((e) => e.value).toSet();
    final genreSet = filterData.genre?.map((e) => e.genre).toSet();
    final versionSet = filterData.version?.map((e) => e.version).toSet();
    final fcTypeSet = filterData.fcType?.map((e) => e.value).toSet();
    final fsTypeSet = filterData.fsType?.map((e) => e.value).toSet();
    final levelValueStart = filterData.levelValueRange?.start;
    final levelValueEnd = filterData.levelValueRange?.end;
    final uploadTimeStart = filterData.uploadTimeRange?.start;
    final uploadTimeEnd = filterData.uploadTimeRange?.end;

    // Pre-filter songs based on genre and version
    final preFilteredSongIds = songs
        .where((song) =>
            (genreSet == null || genreSet.contains(song.genre)) &&
            (versionSet == null || versionSet.contains(song.version)))
        .map((song) => song.id)
        .toSet();

    // Filter records based on song and record-specific criteria
    return records.where((record) {
      // Check if the song ID matches pre-filtered IDs
      if (!preFilteredSongIds.contains(record.id)) {
        return false;
      }

      // Check level index
      if (levelIndexSet != null && !levelIndexSet.contains(record.levelIndex)) {
        return false;
      }

      // Retrieve the corresponding song and difficulties
      final song = songs.firstWhere((song) => song.id == record.id);
      final difficulties = song.difficulties;
      final recordType = record.type;

      // Helper function for level value filtering
      bool isLevelValueOutOfRange(List<SongDifficulty>? diffs) {
        if (diffs == null) return false;
        return diffs.any((diff) =>
            diff.difficulty == record.levelIndex &&
            ((levelValueStart != null && diff.levelValue < levelValueStart) ||
                (levelValueEnd != null && diff.levelValue > levelValueEnd)));
      }

      // Check level value range based on record type
      if (recordType == SongType.dx.value &&
              isLevelValueOutOfRange(difficulties.dx) ||
          recordType == SongType.standard.value &&
              isLevelValueOutOfRange(difficulties.standard) ||
          recordType == SongType.utage.value &&
              isLevelValueOutOfRange(difficulties.utage)) {
        return false;
      }

      // Check upload time
      if (uploadTimeStart != null && uploadTimeEnd != null) {
        final uploadTime = record.uploadTime != null
            ? DateTime.tryParse(record.uploadTime!)
            : null;
        if (uploadTime == null ||
            uploadTime.isBefore(uploadTimeStart) ||
            uploadTime.isAfter(uploadTimeEnd)) {
          return false;
        }
      }

      // Check FC type and FS type
      if ((fcTypeSet != null && !fcTypeSet.contains(record.fc)) ||
          (fsTypeSet != null && !fsTypeSet.contains(record.fs))) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Future<List<SongInfo>> searchSongs(String query) async {
    final aliases = await _lxApiService.getAliasList();
    final songs = await getAllSongs();

    // Convert query to lowercase for case-insensitive search
    final lowerQuery = query.toLowerCase();

    // Create a map of song ID to alias list for fast lookup
    final aliasMap = <int, List<String>>{};
    for (var alias in aliases) {
      aliasMap[alias.songId] =
          alias.aliases.map((e) => e.toLowerCase()).toList();
    }

    // Filter the songs based on query matching
    return songs.where((song) {
      final songTitle = song.title.toLowerCase();
      final songArtist = song.artist.toLowerCase();
      final songIdString = song.id.toString();

      // Check if the song matches by id, title, or artist
      bool matches = songTitle.contains(lowerQuery) ||
          songArtist.contains(lowerQuery) ||
          songIdString.contains(lowerQuery);

      // Check if the song matches by alias
      final songAliases = aliasMap[song.id] ?? [];
      bool aliasMatches =
          songAliases.any((alias) => alias.contains(lowerQuery));

      return matches || aliasMatches;
    }).toList();
  }
}
