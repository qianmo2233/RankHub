import 'dart:async';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:rank_hub/src/model/maimai/song_info.dart';
import 'package:rank_hub/src/provider/lx_mai_provider.dart';
import 'package:rank_hub/src/services/lx_api_services.dart';
import 'package:rank_hub/src/view/maimai/lx_level_view.dart';
import 'package:rank_hub/src/widget/difficulty_card/mai_difficulty_card.dart';
import 'package:rank_hub/src/widget/song_info_list/mai_song_info_list.dart';

class SongDetailScreen extends StatefulWidget {
  const SongDetailScreen({super.key, required this.song});

  final SongInfo song;

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  late AudioPlayer _audioPlayer;
  late AnimationController _iconController;
  late SongInfo _songData = widget.song;
  late StreamSubscription sub1;
  late StreamSubscription sub2;
  late StreamSubscription sub3;

  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isLoaded = false;
  double _currentPosition = 0.0;
  double _totalDuration = 0.0;
  String _version = '';
  double _titleOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (!context.mounted) return;
      setState(() {
        _titleOpacity = ((_scrollController.offset - 178) / 72).clamp(0.0, 1.0);
      });
    });
    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing) {
        if (!context.mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    });
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    sub1 = _audioPlayer.onPositionChanged.listen((Duration p) {
      if (!context.mounted) return;
      setState(() {
        _currentPosition = p.inSeconds.toDouble();
      });
    });
    sub2 = _audioPlayer.onDurationChanged.listen((Duration d) {
      if (!context.mounted) return;
      setState(() {
        _totalDuration = d.inSeconds.toDouble();
      });
    });
    sub3 = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing) {
        if (!context.mounted) return;
        setState(() {
          _isLoading = false;
          _isPlaying = true;
        });
        _iconController.forward();
      } else {
        if (context.mounted) {
          setState(() {
            _isPlaying = false;
          });
          _iconController.reverse();
        }
      }
    });
    getVersion();
    LxApiService.getSongDataById(widget.song.id).then((data) {
      _songData = data;
    });
  }

  @override
  void dispose() {
    sub1.cancel();
    sub2.cancel();
    sub3.cancel();
    _audioPlayer.release();
    _tabController.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> getVersion() async {
    var a = await LxMaiProvider(context: context)
        .lxApiService
        .getTitleByVersion(widget.song.version);
    setState(() {
      _version = a;
    });
  }

  void _playPauseAudio() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else if (!_isLoaded) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _audioPlayer.play(UrlSource(
            'https://assets2.lxns.net/maimai/music/${widget.song.id}.mp3'));
        setState(() {
          _isLoaded = true;
        });
      } catch (e) {
        if (e is TimeoutException) {
          _showSnackbar('加载超时，请重试！');
        } else {
          _showSnackbar('发生错误: $e');
        }
        setState(() {
          _isLoading = false;
          _isPlaying = false;
        });
        return;
      }
    } else {
      _audioPlayer.resume();
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  double _calculateTextWidth(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.size.width;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: NestedScrollView(
        physics: const BouncingScrollPhysics(),
        controller: _scrollController,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              primary: true,
              titleSpacing: 0,
              stretch: true,
              forceElevated: true,
              centerTitle: false,
              backgroundColor:
                  Theme.of(context).scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              title: Opacity(
                  opacity: _titleOpacity,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4), // Rounded corners
                      child: CachedNetworkImage(
                        imageUrl:
                            'https://assets2.lxns.net/maimai/jacket/${widget.song.id}.png',
                        width: 32,
                        height: 32,
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
                    ),
                    title: Text(
                      widget.song.title,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                    ),
                    subtitle: Text(
                      widget.song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
              expandedHeight: 300.0,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.blurBackground],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: 0.5,
                      child: CachedNetworkImage(
                        imageUrl:
                            'https://assets2.lxns.net/maimai/jacket/${widget.song.id}.png',
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.image_not_supported),
                      ),
                    ),
                    buildExtentedContent(),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(
                      text: '曲目信息',
                    ),
                    Tab(text: '谱面信息'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            MaiSongInfoList(song: widget.song, version: _version),
            SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "点击卡片即可查看详细信息",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (int i = widget.song.difficulties.standard.length - 1;
                      i >= 0;
                      i--)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => LxMaiLevelView(
                                difficulty: _songData.difficulties.standard[i],
                                songName: _songData.title),
                          ),
                        );
                      },
                      child: MaiDifficultyCard(
                        songDifficulty: _songData.difficulties.standard[i],
                        songId: widget.song.id,
                      ),
                    ),
                  for (int i = widget.song.difficulties.dx.length - 1;
                      i >= 0;
                      i--)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => LxMaiLevelView(
                                difficulty: _songData.difficulties.dx[i],
                                songName: _songData.title),
                          ),
                        );
                      },
                      child: MaiDifficultyCard(
                        songDifficulty: _songData.difficulties.dx[i],
                        songId: widget.song.id,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildExtentedContent() {
    const double maxWidth = 300;

    const TextStyle titleStyle = TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
    );
    const TextStyle artistStyle = TextStyle(
      fontSize: 16,
    );

    // Calculate the text width
    final double titleWidth =
        _calculateTextWidth(widget.song.title, titleStyle);
    final double artistWidth =
        _calculateTextWidth(widget.song.artist, artistStyle);

    double? progress =
        _totalDuration > 0 ? _currentPosition / _totalDuration : null;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 40,
                child: titleWidth > maxWidth
                    ? SizedBox(
                        width: 299,
                        child: Marquee(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          fadingEdgeEndFraction: 0.1,
                          fadingEdgeStartFraction: 0.1,
                          showFadingOnlyWhenScrolling: true,
                          text: widget.song.title,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          scrollAxis: Axis.horizontal,
                          blankSpace: 20.0,
                          velocity: 50.0,
                          pauseAfterRound: const Duration(seconds: 1),
                        ),
                      )
                    : Text(
                        widget.song.title,
                        style: titleStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 20,
                child: artistWidth > maxWidth
                    ? SizedBox(
                        width: 299,
                        child: Marquee(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          fadingEdgeEndFraction: 0.1,
                          fadingEdgeStartFraction: 0.1,
                          showFadingOnlyWhenScrolling: true,
                          text: widget.song.artist,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                          scrollAxis: Axis.horizontal,
                          blankSpace: 20.0,
                          velocity: 50.0,
                          pauseAfterRound: const Duration(seconds: 1),
                        ),
                      )
                    : Text(
                        widget.song.artist,
                        style: artistStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ],
          ),
          const Spacer(),
          Stack(
            alignment: Alignment.center, // 使内容居中对齐
            children: [
              // 圆形按钮
              SizedBox(
                width: 64,
                height: 64,
                child: ElevatedButton(
                  style: const ButtonStyle(
                    padding: WidgetStatePropertyAll(EdgeInsets.zero),
                    shape: WidgetStatePropertyAll(CircleBorder()),
                  ),
                  onPressed: _playPauseAudio,
                  child: AnimatedIcon(
                    icon: AnimatedIcons.play_pause, // 使用 play/pause 动画
                    progress: _iconController, // 动画控制器
                    size: 32,
                  ),
                ),
              ),
              // 圆形进度指示器
              if (_isLoaded || _isLoading)
                IgnorePointer(
                  ignoring: !_isLoading,
                  child: SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4.0,
                        backgroundColor: Colors.transparent,
                      )),
                )
            ],
          ),
        ],
      ),
    );
  }
}

class _SliverTabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: (Theme.of(context).scaffoldBackgroundColor).withOpacity(0.6),
      child: ClipRect(
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: _tabBar,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverTabDelegate oldDelegate) {
    return false;
  }
}
