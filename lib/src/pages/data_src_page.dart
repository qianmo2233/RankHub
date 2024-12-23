import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:rank_hub/src/pages/add_player_screen.dart';
import 'package:rank_hub/src/widget/player_card/mai_player_card.dart';

class DataSrcPage extends StatefulWidget {
  const DataSrcPage({super.key});

  @override
  State<DataSrcPage> createState() => _DataSrcPageState();
}

class _DataSrcPageState extends State<DataSrcPage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoScaffold(
        body: Builder(builder: (cupertinoScaffoldContext) => DefaultTabController(
            length: 2,
            child: SafeArea(top: false, child: Scaffold(
              appBar: AppBar(
                centerTitle: false,
                title: Text('数据源'),
                automaticallyImplyLeading: false,
                actions: [IconButton(onPressed: () {}, icon: Icon(Icons.sync))],
                bottom: const TabBar(tabs: <Widget>[
                  Tab(
                    text: '玩家数据',
                  ),
                  Tab(
                    text: '游戏数据',
                  ),
                ]),
              ),
              floatingActionButton:FloatingActionButton(
                onPressed: () {
                  CupertinoScaffold.showCupertinoModalBottomSheet(
                    animationCurve: Curves.easeOutCirc,
                    previousRouteAnimationCurve: Curves.easeOutCirc,
                      context: cupertinoScaffoldContext,
                      builder: (context) => AddPlayerScreen());
                },
                child: Icon(Icons.add),
              ),
              floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
              body: TabBarView(
                children: [
                  MaiPlayerCard(),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: ListView(
                      children: [
                        ListTile(
                          leading: CachedNetworkImage(
                            imageUrl: 'https://maimai.lxns.net/favicon.webp',
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            fadeInDuration: const Duration(
                                milliseconds: 500), // Fade-in duration
                            placeholder: (context, url) => Transform.scale(
                              scale: 0.4,
                              child: const CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.image_not_supported),
                          ),
                          title: Text('落雪咖啡屋'),
                          subtitle: Text('maimai.lxns.net'),
                          trailing: Switch(value: true, onChanged: (_) {}),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            )))));
  }
}
