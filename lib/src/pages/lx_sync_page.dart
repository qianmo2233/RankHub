import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:native_flutter_proxy/native_proxy_reader.dart';
import 'package:rank_hub/src/pages/lx_login_page.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:android_intent_plus/android_intent.dart';

class LxSyncPage extends StatefulWidget {
  const LxSyncPage({super.key});

  @override
  _LxSyncPageState createState() => _LxSyncPageState();
}

class _LxSyncPageState extends State<LxSyncPage> {
  int _currentStep = 0;
  bool _proxySet = false;
  bool _syncCompleted = false;
  String _proxyStatus = "检测中...";
  String _syncStatus = "正在生成链接";
  late Dio _dio;
  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  Timer? _proxyCheckTimer;
  Timer? _syncStatusCheckerTimer;
  String? refreshToken;
  String? accessToken;
  String? crawlToken;
  String username = '';
  String oauthLink = '';
  bool loginLoading = true;
  bool linkLoading = true;

  @override
  void initState() {
    super.initState();
    _dio = Dio();
    _initializeNotifications();
    _getUserSession();
  }

  @override
  void dispose() {
    _proxyCheckTimer?.cancel();
    super.dispose();
  }

  void _initializeNotifications() {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _sendNotification(
      String title, String body, String? payload) async {
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'rankhub_channel',
      'RankHub 通知',
      channelDescription: '通知用户',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );
    const iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    await _notificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> _getUserSession() async {
    try {
      refreshToken = (await CookieManager().getCookie(
              url: WebUri.uri(Uri.parse("https://maimai.lxns.net")),
              name: "refresh_token"))
          ?.value;
      if (refreshToken == null) {
        setState(() {
          loginLoading = false;
        });
        return;
      }

      final response = await Dio().get(
        "https://maimai.lxns.net/api/v0/user/refresh",
        options: Options(headers: {"Cookie": 'refresh_token=$refreshToken'}),
      );
      final decodedToken = JwtDecoder.decode(response.data['data']['token']);
      setState(() {
        username = decodedToken['name'] ?? '';
        loginLoading = false;
      });
      if (_currentStep == 0 && username.isNotEmpty) {
        _startProxyCheck();
        _goToNextStep();
      }
    } on DioException {
      setState(() {
        loginLoading = false;
      });
    }
  }

  Future<void> _getCrawlToken() async {
    if (refreshToken == null) return;

    try {
      final response1 = await Dio().get(
        "https://maimai.lxns.net/api/v0/user/refresh",
        options: Options(headers: {"Cookie": 'refresh_token=$refreshToken'}),
      );
      accessToken = response1.data['data']['token'];

      final response2 = await Dio().get(
        "https://maimai.lxns.net/api/v0/user/crawl/token",
        options: Options(headers: {"Authorization": "Bearer $accessToken"}),
      );
      setState(() {
        crawlToken = response2.data['data']['token'];
      });
    } on DioException catch (_) {}
  }

  // 生成 OAuth 链接
  void _getOAuthLink() {
    if (crawlToken == null) return;

    final token = base64.encode(utf8.encode(crawlToken!));
    setState(() {
      oauthLink =
          "https://maimai.lxns.net/api/v0/maimai/wechat/auth?token=$token";
      _syncStatus = "等待微信登录";
    });
  }

  void _startSyncStatusCheck() {
    _proxyCheckTimer?.cancel();
    _syncStatusCheckerTimer?.cancel();
    _proxyCheckTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      try {
        final response1 = await Dio().get(
          "https://maimai.lxns.net/api/v0/user/refresh",
          options: Options(headers: {"Cookie": 'refresh_token=$refreshToken'}),
        );
        accessToken = response1.data['data']['token'];

        final response2 = await Dio().get(
          "https://maimai.lxns.net/api/v0/user/crawl/status",
          options: Options(headers: {"Authorization": "Bearer $accessToken"}),
        );

        if (response2.data['data'] != null) {
          if (response2.data['data']['status'] == 'pending') {
            setState(() {
              _syncStatus = "正在同步游戏数据";
            });
            _sendNotification('微信登录成功', '正在同步游戏数据', null);
          }

          if (response2.data['data']['status'] == 'finished') {
            setState(() {
              _syncStatus = "游戏数据同步成功";
              _syncCompleted = true;
            });
            final startTime =
                DateTime.parse(response2.data['data']['create_time']);
            final endTime =
                DateTime.parse(response2.data['data']['complete_time']);
            final time = endTime.difference(startTime).inSeconds;
            _sendNotification('游戏数据同步成功', '同步耗时: $time 秒', null);
            setState(() {
              _currentStep ++;
            });
          }
        }
      } catch (_) {}
    });
  }

  void _startProxyCheck() {
    _proxyCheckTimer?.cancel();
    _proxyCheckTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      try {
        ProxySetting settings = await NativeProxyReader.proxySetting;
        if (settings.enabled) {
          _dio.httpClientAdapter = IOHttpClientAdapter(createHttpClient: () {
            final client = HttpClient();
            client.findProxy =
                (uri) => 'PROXY ${settings.host}:${settings.port}';
            return client;
          });
        } else {
          _dio.httpClientAdapter = HttpClientAdapter();
        }

        final response = await _dio.get(
          'https://maimai.wahlap.com/maimai-mobile/error/',
        );

        if (response.statusCode != 200) {
          timer.cancel();
          setState(() {
            _proxySet = true;
            _proxyStatus = "代理设置成功！";
            _currentStep = 2;
          });
          await _getCrawlToken();
          _getOAuthLink();
          _startSyncStatusCheck();
          await _sendNotification('代理设置成功', '点击此通知返回应用继续下一步', null);
        }
      } catch (e) {
        timer.cancel();
        setState(() {
          _proxySet = true;
          _proxyStatus = "代理设置成功！";
          _currentStep = 2;
        });
        await _getCrawlToken();
        _getOAuthLink();
        _startSyncStatusCheck();
        await _sendNotification('代理设置成功', '点击此通知返回应用继续下一步', null);
      }
    });
  }

  void _goToNextStep() {
    setState(() {
      if (_currentStep < 3) {
        _currentStep++;
      }
    });
  }

  void _goToSystemWifiSettings() async {
    failToOpenSystemWifiSettings() => {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("无法打开系统WiFi设置")))
    };

    const IOSUrl = "App-Prefs:root=WIFI";
    const AndroidIntent intent = AndroidIntent(action: "android.settings.WIFI_SETTINGS");
    if (Platform.isAndroid) {
      try {
        await intent.launch();
      } catch (e) {
        failToOpenSystemWifiSettings();
      }
    } else if (Platform.isIOS) {
      try {
        await launchUrlString(IOSUrl);
      } catch (e) {
        failToOpenSystemWifiSettings();
      }
    } else {
      failToOpenSystemWifiSettings();
    }
  }

  void _goToWeChat() async {
    const url = "weixin://";
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("无法打开微信")));
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("已复制到剪贴板")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("成绩同步"),
      ),
      body: Stepper(
        controlsBuilder: (BuildContext context, ControlsDetails controls) {
          return const SizedBox.shrink();
        },
        currentStep: _currentStep,
        steps: [
          Step(
            title: Text("登录"),
            content: Builder(
                builder: (_) => loginLoading
                    ? Column(children: [
                        SizedBox(height: 16),
                        Row(
                          children: [
                            SizedBox(width: 16),
                            CircularProgressIndicator(),
                            SizedBox(width: 16),
                            Expanded(child: Text("正在获取登录状态")),
                          ],
                        )
                      ])
                    : username.isEmpty
                        ? SizedBox(
                            width: double.infinity,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      final refreshToken = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                LxLoginPage()),
                                      );

                                      if (refreshToken != null) {
                                        _getUserSession();
                                      }
                                    },
                                    child: Text('登录并获取 Refresh Token'),
                                  )
                                ]))
                        : SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("当前登录用户: $username"),
                                SizedBox(
                                  height: 16,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        _startProxyCheck();
                                        setState(() {
                                          _currentStep++;
                                        });
                                      },
                                      child: Text('下一步'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        setState(() {
                                          username = '';
                                          loginLoading = true;
                                        });
                                        CookieManager().deleteAllCookies();
                                        final refreshToken =
                                            await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  LxLoginPage()),
                                        );

                                        if (refreshToken != null) {
                                          _getUserSession();
                                        }
                                      },
                                      child: Text('重新登录'),
                                    ),
                                  ],
                                ),
                              ],
                            ))),
            isActive: _currentStep >= 0,
            state: username.isNotEmpty ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: Text("设置代理"),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    SizedBox(height: 16),
                    TextFormField(
                      readOnly: true,
                      initialValue: "proxy.maimai.lxns.net",
                      decoration: InputDecoration(
                        labelText: "服务器",
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                            onPressed: () {
                              _copyToClipboard("proxy.maimai.lxns.net");
                            },
                            icon: Icon(Icons.copy)),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      readOnly: true,
                      initialValue: "8080",
                      decoration: InputDecoration(
                        labelText: "端口",
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                            onPressed: () {
                              _copyToClipboard("8080");
                            },
                            icon: Icon(Icons.copy)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _goToSystemWifiSettings,
                      child: Text("转到系统WiFi设置"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _proxyCheckTimer?.cancel();
                        setState(() {
                          _currentStep--;
                        });
                      },
                      child: Text("切换账号"),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Expanded(child: Text("代理检测状态: $_proxyStatus")),
                  ],
                ),
              ],
            ),
            isActive: _currentStep >= 1,
            state: _proxySet ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: Text("同步数据"),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    SizedBox(height: 16),
                    if (oauthLink.isNotEmpty)
                      TextFormField(
                        readOnly: true,
                        initialValue: oauthLink,
                        decoration: InputDecoration(
                          labelText: "OAuth 链接",
                          border: OutlineInputBorder(),
                          suffixIcon: IconButton(
                              onPressed: () {
                                _copyToClipboard(oauthLink);
                              },
                              icon: Icon(Icons.copy)),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    _copyToClipboard(oauthLink);
                    _goToWeChat();
                    Timer(Duration(seconds: 1), () {
                      _sendNotification("登录链接已复制", "请将链接发送至安全的聊天中并打开", null);
                    });
                  },
                  child: Text("复制链接并打开微信"),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Expanded(child: Text("数据同步状态: $_syncStatus")),
                  ],
                ),
              ],
            ), //修改此处代码，
            isActive: _currentStep >= 2 || _syncCompleted,
            state: StepState.indexed,
          ),
          Step(
            title: Text("完成"),
            content: Text("游戏数据同步成功"),
            isActive: _currentStep >= 3,
            state: StepState.indexed,
          ),
        ],
      ),
    );
  }
}
