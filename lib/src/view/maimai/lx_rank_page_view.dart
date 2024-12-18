import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:rank_hub/src/pages/player_switch_page.dart';
import 'package:rank_hub/src/view/maimai/lx_b50_export_view.dart';
import 'package:rank_hub/src/view/maimai/lx_mai_record_card.dart';
import 'package:rank_hub/src/view/maimai/lx_record_list_view.dart';
import 'package:rank_hub/src/viewmodel/maimai/lx_rank_page_vm.dart';

class MaiRankPage extends StatelessWidget {
  const MaiRankPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) {
        final viewModel = MaiRankViewModel(ctx);
        viewModel.initialize(); // 启动异步初始化任务
        return viewModel;
      },
      child: Consumer<MaiRankViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            // 显示加载状态
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // 主界面
          return CupertinoScaffold(
              body: Builder(
                  builder: (cupertinoScaffoldContext) => DefaultTabController(
                      length: 2,
                      child: DefaultTabController(
                          length: 2,
                          initialIndex: 0,
                          child: Scaffold(
                            extendBody: true,
                            extendBodyBehindAppBar: true,
                            appBar: AppBar(
                              backgroundColor: Theme.of(context)
                                  .scaffoldBackgroundColor
                                  .withOpacity(0.9),
                              surfaceTintColor: Colors.transparent,
                              centerTitle: false,
                              automaticallyImplyLeading: false,
                              flexibleSpace: ClipRRect(
                                  child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 8, sigmaY: 8),
                                      child: Container(
                                          color: Colors.transparent))),
                              bottom: const TabBar(tabs: [
                                Tab(text: '所有成绩'),
                                Tab(text: 'B50'),
                              ]),
                              title: TextButton(
                                onPressed: () {
                                  CupertinoScaffold
                                      .showCupertinoModalBottomSheet(
                                          animationCurve: Curves.easeOutCirc,
                                          previousRouteAnimationCurve:
                                              Curves.easeOutCirc,
                                          context: cupertinoScaffoldContext,
                                          builder: (context) =>
                                              const PlayerSwitchPage());
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("${viewModel.playerName} (舞萌 DX)"),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                              actions: const [
                                IconButton(
                                    //onPressed: () {ProxyServer().startProxyServer();},
                                    onPressed: null,
                                    icon: Icon(Icons.more_vert)),
                                SizedBox(width: 8),
                              ],
                            ),
                            body: TabBarView(
                              children: [
                                const LxMaiRecordList(),
                                RefreshIndicator(
                                    onRefresh: () => viewModel.initialize(),
                                    child: ListView(
                                      children: [
                                        Column(
                                          children: [
                                            SizedBox(
                                              width: double.infinity,
                                              height: 140,
                                              child: Column(
                                                children: [
                                                  SizedBox(height: 32),
                                                  Row(
                                                    children: [
                                                      SizedBox(width: 32),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            "当前 RATING",
                                                            style: TextStyle(
                                                                fontSize: 24,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                          SizedBox(height: 16),
                                                          SizedBox(
                                                            height: 40, // 明确的高度
                                                            child: viewModel
                                                                .getShaderMaskByRating(
                                                              viewModel
                                                                  .playerRating,
                                                              Text(
                                                                viewModel
                                                                    .playerRating
                                                                    .toString(),
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        24,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Spacer(),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                              "当期版本 Rating: ${viewModel.currentVerRating}"),
                                                          SizedBox(
                                                              height:
                                                                  16), // 替换 Spacer，避免无约束布局
                                                          Text(
                                                              "往期版本 Rating: ${viewModel.pastVerRating}"),
                                                        ],
                                                      ),
                                                      SizedBox(width: 32)
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                            Center(
                                                child: ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            fullscreenDialog:
                                                                true,
                                                            builder: (context) =>
                                                                LxB50ExportView(
                                                                    viewModel:
                                                                        viewModel)),
                                                      );
                                                    },
                                                    child: Text('导出 B50 成绩图'))),
                                            SizedBox(height: 16),
                                            const Center(
                                              child: Text(
                                                '当期版本成绩',
                                                style: TextStyle(fontSize: 16),
                                              ),
                                            ),
                                            SizedBox(
                                                height: 280,
                                                child: GridView.builder(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  gridDelegate:
                                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                                    maxCrossAxisExtent: 300,
                                                    childAspectRatio: 0.6,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.all(16),
                                                  itemCount: viewModel
                                                      .b15Records.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    return LxMaiRecordCard(
                                                      recordData: viewModel
                                                          .b15Records[index],
                                                    );
                                                  },
                                                )),
                                            const Center(
                                              child: Text(
                                                '往期版本成绩',
                                                style: TextStyle(fontSize: 16),
                                              ),
                                            ),
                                            SizedBox(
                                                height: 280,
                                                child: GridView.builder(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  gridDelegate:
                                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                                    maxCrossAxisExtent: 300,
                                                    childAspectRatio: 0.6,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.all(16),
                                                  itemCount: viewModel
                                                      .b35Records.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    return LxMaiRecordCard(
                                                      recordData: viewModel
                                                          .b35Records[index],
                                                    );
                                                  },
                                                )),
                                          ],
                                        )
                                      ],
                                    )),
                              ],
                            ),
                          )))));
        },
      ),
    );
  }
}
