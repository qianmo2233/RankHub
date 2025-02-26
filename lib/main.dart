import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rank_hub/src/model/maimai/collection.dart' as mai;
import 'package:rank_hub/src/model/maimai/game_data.dart' as mai;
import 'package:rank_hub/src/model/maimai/player_data.dart' as mai;
import 'package:rank_hub/src/model/maimai/song_alias.dart' as mai;
import 'package:rank_hub/src/model/maimai/song_difficulties.dart' as mai;
import 'package:rank_hub/src/model/maimai/song_difficulty.dart' as mai;
import 'package:rank_hub/src/model/maimai/song_genre.dart' as mai;
import 'package:rank_hub/src/model/maimai/song_info.dart' as mai;
import 'package:rank_hub/src/model/maimai/song_notes.dart' as mai;
import 'package:rank_hub/src/model/maimai/song_score.dart' as mai;
import 'package:rank_hub/src/model/maimai/song_version.dart' as mai;
import 'package:rank_hub/src/provider/data_source_manager.dart';
import 'package:rank_hub/src/provider/lx_mai_provider.dart';
import 'package:rank_hub/src/provider/player_manager.dart';

import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';

void main() async {
  // Set up the SettingsController, which will glue user settings to multiple
  // Flutter Widgets.
  final settingsController = SettingsController(SettingsService());

  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();

  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initHive();

  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes, then passes it further down to the
  // SettingsView.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PlayerManager>(
          create: (context) => PlayerManager(),
        ),
        ChangeNotifierProvider(
            create: (context) => DataSourceManager(initialDataSources: [
                  LxMaiProvider(context: context),
                ])),
      ],
      child: MyApp(settingsController: settingsController),
    ),
  );
}

Future<void> initHive() async {
  Hive.initFlutter();

  //maimai
  Hive.registerAdapter(mai.SongScoreAdapter());
  Hive.registerAdapter(mai.SongInfoAdapter());
  Hive.registerAdapter(mai.SongAliasAdapter());
  Hive.registerAdapter(mai.SongGenreAdapter());
  Hive.registerAdapter(mai.SongVersionAdapter());
  Hive.registerAdapter(mai.SongNotesAdapter());
  Hive.registerAdapter(mai.BuddyNotesAdapter());
  Hive.registerAdapter(mai.SongDifficultyAdapter());
  Hive.registerAdapter(mai.SongDifficultiesAdapter());
  Hive.registerAdapter(mai.GameDataAdapter());
  Hive.registerAdapter(mai.PlayerDataAdapter());
  Hive.registerAdapter(mai.CollectionAdapter());
}
