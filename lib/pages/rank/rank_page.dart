import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rank_hub/core/core_context.dart';
import 'package:rank_hub/core/game.dart';
import 'package:rank_hub/pages/rank/rank_view_model.dart';
import 'dart:ui';

class RankPage extends ConsumerWidget {
  const RankPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appContext = ref.watch(appContextProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('排行榜'),
        titleSpacing: 24,
        centerTitle: false,
        actions: [
          // 账号选择按钮（如果有账号）
          if (appContext?.hasAccount ?? false)
            IconButton(
              onPressed: () => _showAccountSelector(context, ref),
              icon: const Icon(Icons.account_circle),
              tooltip: '切换账号',
            ),
          // 游戏选择按钮
          TextButton.icon(
            onPressed: () => _showGameSelector(context, ref),
            icon: const Icon(Icons.gamepad, size: 20),
            label: Text(appContext?.game.name ?? '选择游戏'),
          ),
        ],
      ),
      body: _buildBody(context, ref, appContext),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AppContext? appContext,
  ) {
    if (appContext == null) {
      return _buildEmptyView(context, '暂未选择游戏', '点击右上角按钮选择游戏');
    }

    // 排行榜通常需要账号
    if (!appContext.hasAccount) {
      return _buildEmptyView(
        context,
        '需要登录账号',
        '排行榜功能需要登录账号才能使用\n点击右上角选择或登录账号',
      );
    }

    return _buildGameContent(context, ref, appContext.game);
  }

  /// 显示游戏选择器 BottomSheet
  void _showGameSelector(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final appContext = ref.watch(appContextProvider);
          final notifier = ref.read(rankProvider.notifier);
          final games = notifier.getAvailableGames();

          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 标题栏
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Text(
                              '选择游戏',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1),

                      // 游戏列表
                      Flexible(
                        child: games.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.videogame_asset_off,
                                      size: 48,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '暂无可用游戏',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: games.length,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                itemBuilder: (context, index) {
                                  final game = games[index];
                                  final isSelected = game == appContext?.game;

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isSelected
                                          ? colorScheme.primaryContainer
                                          : colorScheme.surfaceContainerHighest,
                                      child: Icon(
                                        Icons.videogame_asset,
                                        color: isSelected
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    title: Text(
                                      game.name,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    subtitle: Text('ID: ${game.id.value}'),
                                    trailing: isSelected
                                        ? Icon(
                                            Icons.check_circle,
                                            color: colorScheme.primary,
                                          )
                                        : null,
                                    selected: isSelected,
                                    onTap: () {
                                      notifier.selectGame(game);
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 显示账号选择器
  void _showAccountSelector(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final appContext = ref.watch(appContextProvider);
          final notifier = ref.read(rankProvider.notifier);

          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 标题栏
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Text(
                              '选择账号',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1),

                      // 账号列表
                      Flexible(
                        child: FutureBuilder(
                          future: notifier.getAccountsForPlatform(
                            appContext?.scope.platformId.value ?? '',
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final accounts = snapshot.data ?? [];

                            if (accounts.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.account_circle_outlined,
                                      size: 48,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '暂无可用账号',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: accounts.length,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemBuilder: (context, index) {
                                final accountEntity = accounts[index];
                                final isSelected =
                                    accountEntity.accountIdentifier ==
                                    appContext?.scope.accountIdentifier;

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? colorScheme.primaryContainer
                                        : colorScheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.account_circle,
                                      color: isSelected
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  title: Text(
                                    accountEntity.displayName,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Text(
                                    accountEntity.accountIdentifier,
                                  ),
                                  trailing: isSelected
                                      ? Icon(
                                          Icons.check_circle,
                                          color: colorScheme.primary,
                                        )
                                      : null,
                                  selected: isSelected,
                                  onTap: () {
                                    notifier.selectAccountForCurrentGame(
                                      accountEntity.platformId,
                                      accountEntity.accountIdentifier,
                                    );
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建游戏内容
  Widget _buildGameContent(BuildContext context, WidgetRef ref, Game game) {
    final descriptor = game.descriptor;
    final scorePages = descriptor.scorePages;

    if (scorePages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '该游戏暂无排行榜内容',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // 如果只有一个页面,直接显示
    if (scorePages.length == 1) {
      return scorePages.first.builder(context);
    }

    // 多个页面时使用 TabBar
    return DefaultTabController(
      length: scorePages.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: scorePages
                .map((page) => Tab(text: page.title, icon: Icon(page.icon)))
                .toList(),
          ),
          Expanded(
            child: TabBarView(
              children: scorePages
                  .map((page) => page.builder(context))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空视图
  Widget _buildEmptyView(BuildContext context, String title, String message) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 80,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
