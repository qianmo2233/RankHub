import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rank_hub/games/maimai/maimai_providers.dart';
import 'package:rank_hub/games/maimai/models/maimai_song.dart';
import 'package:rank_hub/games/maimai/widgets/song_list_item.dart';

class SongListView extends ConsumerWidget {
  const SongListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourceState = ref.watch(maimaiSongListProvider);

    return switch (resourceState) {
      AsyncData<List<MaimaiSong>>(:final value) => RefreshIndicator(
        onRefresh: () async {
          await ref.read(maimaiSongListProvider.notifier).refresh();
        },
        child: ListView.builder(
          itemCount: value.length,
          itemBuilder: (context, index) {
            final song = value[index];
            return SongListItem(song: song);
          },
        ),
      ),
      AsyncLoading() => const Center(child: CircularProgressIndicator()),
      AsyncError(:final error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              '加载歌曲列表时出错:\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                await ref.read(maimaiSongListProvider.notifier).refresh();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    };
  }
}
