import 'package:rank_hub/core/account.dart';
import 'package:rank_hub/core/game_id.dart';
import 'package:rank_hub/core/platform_id.dart';
import 'package:rank_hub/core/resource_key.dart';

abstract class PlatformAdapter {
  PlatformId get id;

  bool supports(GameId gameId);

  Future<T?> fetchResource<T>(ResourceKey key, Account account);
}
