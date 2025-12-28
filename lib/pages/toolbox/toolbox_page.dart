import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rank_hub/core/core_context.dart';
import 'package:rank_hub/core/game.dart';
import 'package:rank_hub/pages/toolbox/toolbox_view_model.dart';
import 'dart:ui';

class ToolboxPage extends ConsumerWidget {
  const ToolboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appContext = ref.watch(appContextProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('工具箱'),
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
          final notifier = ref.read(toolboxProvider.notifier);
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

  /// 显示账号选择器 BottomSheet
  void _showAccountSelector(BuildContext context, WidgetRef ref) {
    final appContext = ref.read(appContextProvider);
    if (appContext == null) return;

    final colorScheme = Theme.of(context).colorScheme;
    final notifier = ref.read(toolboxProvider.notifier);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ClipRRect(
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
                        appContext.scope.platformId.value,
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final accounts = snapshot.data!;
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
                                  '暂无账号',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '请先登录平台账号',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: accounts.length + 1,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemBuilder: (context, index) {
                            // 第一项：不选择账号
                            if (index == 0) {
                              final isSelected = !appContext.hasAccount;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isSelected
                                      ? colorScheme.errorContainer
                                      : colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.person_off,
                                    color: isSelected
                                        ? colorScheme.onErrorContainer
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                title: const Text('不选择账号'),
                                subtitle: const Text('仅查看公开数据'),
                                trailing: isSelected
                                    ? Icon(
                                        Icons.check_circle,
                                        color: colorScheme.primary,
                                      )
                                    : null,
                                selected: isSelected,
                                onTap: () {
                                  notifier.clearAccountForCurrentGame();
                                  Navigator.pop(context);
                                },
                              );
                            }

                            final account = accounts[index - 1];
                            final isSelected =
                                appContext.scope.accountIdentifier ==
                                account.accountIdentifier;

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
                                account.displayName,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(account.accountIdentifier),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color: colorScheme.primary,
                                    )
                                  : null,
                              selected: isSelected,
                              onTap: () {
                                notifier.selectAccountForCurrentGame(
                                  appContext.scope.platformId.value,
                                  account.accountIdentifier,
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
      ),
    );
  }

  /// 构建游戏内容
  Widget _buildGameContent(BuildContext context, WidgetRef ref, Game game) {
    final descriptor = game.descriptor;
    final toolboxPages = descriptor.toolboxPages;

    if (toolboxPages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '该游戏暂无工具箱内容',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // 如果只有一个页面,直接显示
    if (toolboxPages.length == 1) {
      return toolboxPages.first.builder(context);
    }

    // 多个页面时使用 TabBar
    return DefaultTabController(
      length: toolboxPages.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: toolboxPages
                .map((page) => Tab(text: page.title, icon: Icon(page.icon)))
                .toList(),
          ),
          Expanded(
            child: TabBarView(
              children: toolboxPages
                  .map((page) => page.builder(context))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空视图
  Widget _buildEmptyView(BuildContext context, String title, String subtitle) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_outlined,
            size: 80,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
