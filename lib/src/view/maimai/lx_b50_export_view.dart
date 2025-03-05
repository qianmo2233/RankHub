import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:rank_hub/src/view/maimai/lx_mai_record_card.dart';
import 'package:rank_hub/src/viewmodel/maimai/lx_rank_page_vm.dart';

class LxB50ExportView extends StatelessWidget {
  final MaiRankViewModel viewModel;

  LxB50ExportView({super.key, required this.viewModel});

  final GlobalKey combinedKey = GlobalKey();

  Future<void> _saveToGallery(Uint8List pngBytes, BuildContext context) async {
    try {
      final currentTime = () {
        DateTime now = DateTime.now();
        return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}";
      }();
      final result = await ImageGallerySaverPlus.saveImage(
        Uint8List.fromList(pngBytes),
        quality: 100,
        name: "B15_B35_Scores_$currentTime",
      );
      print("Image saved to gallery: $result");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("保存成功"))
      );
    } catch (e) {
      print("Error saving image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("保存失败（$e）"))
      );
    }
  }

  Future<void> _generateAndSaveImage(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("正在保存"))
      );
      
      RenderRepaintBoundary boundary = combinedKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image =
          await boundary.toImage(pixelRatio: 7.0); // High-quality scaling
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      await _saveToGallery(pngBytes, context);
    } catch (e) {
      print("Error generating or saving image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const int b15RowCount = 5; // Number of columns for B15
    const int b35RowCount = 5; // Number of columns for B35

    final b15Height = (viewModel.b15Records.length / b15RowCount).ceil() * 240;
    final b35Height = (viewModel.b35Records.length / b35RowCount).ceil() * 240;

    final totalHeight = b15Height + b35Height + 1000; // Add padding for labels

    return Scaffold(
        appBar: AppBar(
          title: const Text('导出 B50 成绩图'),
          actions: [
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () => _generateAndSaveImage(context),
            ),
          ],
        ),
        body: RepaintBoundary(
          key: combinedKey,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/images/maimai_bud.jpg'), // Background image
                fit: BoxFit.cover, // Cover the entire area
              ),
            ),
            child: Center(
              child: FittedBox(
                child: SizedBox(
                  width: 1832, // Fixed width for clarity in images
                  height: totalHeight.toDouble(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 72),
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 32),
                            child: SizedBox(
                                width: 1000,
                                height: 160,
                                child: Card(
                                  clipBehavior: Clip.hardEdge,
                                  child: Stack(
                                    children: [
                                      // 背景容器，显示牌面图和渐变效果
                                      Positioned.fill(
                                        child: ShaderMask(
                                          shaderCallback: (bounds) =>
                                              LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              Colors.black.withOpacity(0.7),
                                              Colors.transparent,
                                            ],
                                            tileMode: TileMode.clamp,
                                          ).createShader(bounds),
                                          blendMode: BlendMode.srcOver,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              image: DecorationImage(
                                                image: NetworkImage(
                                                  'https://assets.lxns.net/maimai/plate/${viewModel.playerData.namePlate?.id}.png',
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // 玩家信息 (头像和文字)
                                      Padding(
                                          padding: EdgeInsets.only(left: 16),
                                          child: ListTile(
                                            contentPadding: EdgeInsets.all(16),
                                            leading: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: CachedNetworkImage(
                                                imageUrl:
                                                    'https://assets.lxns.net/maimai/icon/${viewModel.playerData.icon?.id}.png',
                                                fit: BoxFit.cover,
                                                fadeInDuration: const Duration(
                                                    milliseconds: 500),
                                                placeholder: (context, url) =>
                                                    Transform.scale(
                                                  scale: 0.4,
                                                  child:
                                                      const CircularProgressIndicator(),
                                                ),
                                                errorWidget: (context, url,
                                                        error) =>
                                                    const Icon(Icons
                                                        .image_not_supported),
                                              ),
                                            ),
                                            title: Text(
                                              viewModel.playerData.name,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 48),
                                            ), // 玩家姓名
                                            subtitle: const Text(
                                              '  舞萌 DX B50 成绩图',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          )),
                                    ],
                                  ),
                                )),
                          ),
                          Spacer(),
                          Padding(
                              padding: EdgeInsets.only(right: 32),
                              child: SizedBox(
                                  width: 400,
                                  height: 160,
                                  child: Card(
                                    child: Column(
                                      children: [
                                        SizedBox(height: 32),
                                        Row(
                                          children: [
                                            SizedBox(width: 32),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "当前 RATING",
                                                  style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                SizedBox(height: 16),
                                                SizedBox(
                                                  height: 40, // 明确的高度
                                                  child: viewModel
                                                      .getShaderMaskByRating(
                                                    viewModel.playerRating,
                                                    Text(
                                                      viewModel.playerRating
                                                          .toString(),
                                                      style: TextStyle(
                                                          fontSize: 24,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Spacer(),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
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
                                            SizedBox(width: 16)
                                          ],
                                        )
                                      ],
                                    ),
                                  )))
                        ],
                      ),
                      SizedBox(height: 128),
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const ui.Color.fromARGB(255, 40, 40, 40),
                            borderRadius: BorderRadius.circular(48),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          child: Text(
                            "  当期版本成绩 B15  ",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // B15 Grid
                      SizedBox(
                          height: 740,
                          child: GridView.builder(
                            scrollDirection: Axis.vertical,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              mainAxisExtent: 240,
                              childAspectRatio: 1.3,
                            ),
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: viewModel.b15Records.length,
                            itemBuilder: (context, index) {
                              return LxMaiRecordCard(
                                recordData: viewModel.b15Records[index],
                              );
                            },
                          )),
                      // B35 Grid

                      SizedBox(height: 72),
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const ui.Color.fromARGB(255, 40, 40, 40),
                            borderRadius: BorderRadius.circular(48),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          child: Text(
                            "  往期版本成绩 B35  ",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 1800,
                        child: GridView.builder(
                          scrollDirection: Axis.vertical,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisExtent: 240,
                            childAspectRatio: 1.3,
                          ),
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: viewModel.b35Records.length,
                          itemBuilder: (context, index) {
                            return LxMaiRecordCard(
                              recordData: viewModel.b35Records[index],
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 72),
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const ui.Color.fromARGB(255, 40, 40, 40),
                            borderRadius: BorderRadius.circular(48),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          child: Text(
                            "  本图使用 RankHub App 生成  ",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}
