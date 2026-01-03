import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rank_hub/core/core_context.dart';
import 'package:rank_hub/core/game.dart';
import 'package:rank_hub/pages/library/library_view_model.dart';
import 'dart:ui';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听 libraryProvider 以触发初始化
    ref.watch(libraryProvider);
    final appContext = ref.watch(appContextProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('资料库'),
        titleSpacing: 24,
        centerTitle: false,
        actions: [
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
      return _buildEmptyView(context);
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
          final notifier = ref.read(libraryProvider.notifier);
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
                                    onTap: () async {
                                      await notifier.selectGame(game);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
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
    final libraryPages = descriptor.libraryPages;

    if (libraryPages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '该游戏暂无资料库内容',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // 如果只有一个页面,直接显示
    if (libraryPages.length == 1) {
      return libraryPages.first.builder(context);
    }

    // 多个页面时使用 TabBar
    return DefaultTabController(
      length: libraryPages.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: libraryPages
                .map((page) => Tab(text: page.title, icon: Icon(page.icon)))
                .toList(),
          ),
          Expanded(
            child: TabBarView(
              children: libraryPages
                  .map((page) => page.builder(context))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空视图
  Widget _buildEmptyView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 80,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 24),
          Text(
            '暂未选择游戏',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '点击右上角按钮选择游戏',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
