import 'package:flutter/material.dart';
import 'package:rank_hub/core/game.dart';
import 'package:rank_hub/core/game_id.dart';
import 'package:rank_hub/core/geme_descriptor.dart';
import 'package:rank_hub/core/page_descriptor.dart';
import 'package:rank_hub/games/maimai/views/song_list_view.dart';

class Maimai extends Game {
  @override
  final GameId id = const GameId(
    name: "maimai",
    version: "DX",
    platform: "arcade",
    region: "CN",
  );

  @override
  GameDescriptor get descriptor => GameDescriptor(
    libraryPages: [
      PageDescriptor(
        title: '曲库',
        icon: Icons.library_music,
        builder: (_) => SongListView(),
      ),
    ],
    scorePages: [],
    toolboxPages: [],
    profilePages: [],
    resources: [],
    tools: [],
  );

  @override
  String get name => "舞萌 DX";
}
