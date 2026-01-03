import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rank_hub/core/resource_notifier.dart';
import 'package:rank_hub/games/maimai/maimai_resources.dart';
import 'package:rank_hub/games/maimai/models/maimai_score.dart';
import 'package:rank_hub/games/maimai/models/maimai_song.dart';

/// Maimai 曲目列表 Provider
final maimaiSongListProvider = createResourceProvider(
  maimaiSongListResourceKey,
);

/// Maimai 成绩列表 Provider
final maimaiScoreListProvider = createResourceProvider(
  maimaiScoreListResourceKey,
);

final maimaiSongByIdProvider = Provider.family<MaimaiSong?, int>((ref, songId) {
  return ref.watch(
    maimaiSongListProvider.select(
      (async) => async.value?.firstWhereOrNull((s) => s.id == songId),
    ),
  );
});

final maimaiScoreByIdProvider = Provider.family<MaimaiScore?, int>((
  ref,
  songId,
) {
  return ref.watch(
    maimaiScoreListProvider.select(
      (async) => async.value?.firstWhereOrNull((s) => s.songId == songId),
    ),
  );
});
