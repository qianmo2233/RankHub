import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rank_hub/core/account.dart' as core;
import 'package:rank_hub/platform/lxns/lxns_oauth2_helper.dart';

/// 落雪咖啡屋登录页面
class LxnsLoginPage extends StatefulWidget {
  const LxnsLoginPage({super.key});

  @override
  State<LxnsLoginPage> createState() => _LxnsLoginPageState();
}

class _LxnsLoginPageState extends State<LxnsLoginPage> {
  bool _isLoading = false;
  final LxnsOAuth2Helper _oauth2Helper = LxnsOAuth2Helper();

  /// 自动跳转登录
  Future<void> _startAutoLogin() async {
    setState(() => _isLoading = true);

    try {
      final authParams = _oauth2Helper.generateAuthUrl(manual: false);
      final authUrl = authParams['auth_url']!;
      final codeVerifier = authParams['code_verifier']!;
      final state = authParams['state']!;

      print('🔐 开始 OAuth2 授权...');
      print('📤 授权 URL: $authUrl');

      // 使用 flutter_web_auth_2 打开授权页面
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: 'rankhub',
      );

      print('📥 收到回调: $result');

      // 解析回调 URL
      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];
      final returnedState = uri.queryParameters['state'];

      if (code == null) {
        throw Exception('未收到授权码');
      }

      if (returnedState != state) {
        throw Exception('State 验证失败');
      }

      print('✅ 授权码获取成功');

      // 交换 token
      final tokenData = await _oauth2Helper.exchangeCodeForToken(
        code: code,
        codeVerifier: codeVerifier,
        clientId: authParams['client_id']!,
        redirectUri: authParams['redirect_uri']!,
      );

      if (tokenData == null) {
        throw Exception('交换 token 失败');
      }

      // 获取用户信息
      final authResult = await _oauth2Helper.fetchUserInfo(tokenData);
      if (authResult == null) {
        throw Exception('获取用户信息失败');
      }

      // 创建 Account 对象
      final account = core.Account(
        platformId: 'lxns',
        credentials: authResult.credentials,
      );

      if (mounted) {
        Navigator.pop(context, account);
      }
    } catch (e) {
      print('❌ 登录失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('登录失败: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  /// 手动输入授权码登录
  Future<void> _startManualLogin() async {
    if (!mounted) return;

    final authParams = _oauth2Helper.generateAuthUrl(manual: true);
    final authUrl = authParams['auth_url']!;
    final codeVerifier = authParams['code_verifier']!;
    final clientId = authParams['client_id']!;
    final redirectUri = authParams['redirect_uri']!;

    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => _ManualAuthPage(authUrl: authUrl),
        fullscreenDialog: true,
      ),
    );

    if (code == null || code.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 交换 token
      final tokenData = await _oauth2Helper.exchangeCodeForToken(
        code: code,
        codeVerifier: codeVerifier,
        clientId: clientId,
        redirectUri: redirectUri,
      );

      if (tokenData == null) {
        throw Exception('交换 token 失败');
      }

      // 获取用户信息
      final authResult = await _oauth2Helper.fetchUserInfo(tokenData);
      if (authResult == null) {
        throw Exception('获取用户信息失败');
      }

      // 创建 Account 对象
      final account = core.Account(
        platformId: 'lxns',
        credentials: authResult.credentials,
      );

      if (mounted) {
        Navigator.pop(context, account);
      }
    } catch (e) {
      print('❌ 登录失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('登录失败: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('落雪咖啡屋登录')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner 图片
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CachedNetworkImage(
                          imageUrl:
                              'https://maimai.lxns.net/logo_background.webp',
                          width: double.infinity,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.coffee,
                                size: 64,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: CachedNetworkImage(
                            imageUrl:
                                'https://maimai.lxns.net/logo_foreground.webp',
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const SizedBox(),
                            errorWidget: (context, url, error) =>
                                const SizedBox(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '落雪咖啡屋',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '使用 OAuth2 安全授权登录',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // 功能说明
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '登录说明',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '选择一种登录方式：',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '方式1：自动跳转（推荐）\n'
                            '• 打开浏览器进行授权\n'
                            '• 授权成功后自动返回应用\n\n'
                            '方式2：手动输入授权码\n'
                            '• 适用于自动跳转失败的情况\n'
                            '• 需要手动复制授权码',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 登录按钮
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _startAutoLogin,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(_isLoading ? '登录中...' : '自动跳转登录'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _startManualLogin,
                    icon: const Icon(Icons.edit),
                    label: const Text('手动输入授权码'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 手动授权页面
class _ManualAuthPage extends StatefulWidget {
  final String authUrl;

  const _ManualAuthPage({required this.authUrl});

  @override
  State<_ManualAuthPage> createState() => _ManualAuthPageState();
}

class _ManualAuthPageState extends State<_ManualAuthPage> {
  final TextEditingController _codeController = TextEditingController();
  final ChromeSafariBrowser _browser = ChromeSafariBrowser();
  bool _browserOpened = false;

  @override
  void dispose() {
    _codeController.dispose();
    _browser.close();
    super.dispose();
  }

  Future<void> _openBrowser() async {
    if (_browserOpened) return;

    setState(() => _browserOpened = true);

    try {
      try {
        await _browser.open(
          url: WebUri(widget.authUrl),
          settings: ChromeSafariBrowserSettings(
            shareState: CustomTabsShareState.SHARE_STATE_OFF,
            barCollapsingEnabled: true,
          ),
        );
        return;
      } on PlatformException {
        // 降级方案：使用 url_launcher
        final Uri authUri = Uri.parse(widget.authUrl);
        if (await canLaunchUrl(authUri)) {
          await launchUrl(authUri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('无法打开浏览器');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('打开浏览器失败: $e')));
      }
      setState(() => _browserOpened = false);
    }
  }

  void _submitCode() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入授权码')));
      return;
    }
    Navigator.pop(context, code);
  }

  Widget _buildStep(
    BuildContext context,
    String number,
    String title,
    String description,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('授权登录')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '操作步骤',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildStep(
                            context,
                            '1',
                            '点击下方按钮打开浏览器',
                            '在浏览器中登录您的落雪咖啡屋账号',
                          ),
                          const SizedBox(height: 12),
                          _buildStep(context, '2', '完成授权', '在浏览器页面中确认授权'),
                          const SizedBox(height: 12),
                          _buildStep(
                            context,
                            '3',
                            '复制授权码',
                            '授权成功后，页面会显示授权码，请复制',
                          ),
                          const SizedBox(height: 12),
                          _buildStep(context, '4', '粘贴并提交', '返回此页面，粘贴授权码并点击确认'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _browserOpened ? null : _openBrowser,
                    icon: Icon(
                      _browserOpened ? Icons.check : Icons.open_in_browser,
                    ),
                    label: Text(_browserOpened ? '浏览器已打开' : '打开浏览器授权'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 授权码输入区域
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 0,
                    color: colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '完成授权后，页面会显示授权码，请复制并粘贴到下方',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: '授权码',
                      hintText: '请输入或粘贴授权码',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.vpn_key),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.paste),
                        onPressed: () async {
                          final data = await Clipboard.getData(
                            Clipboard.kTextPlain,
                          );
                          if (data?.text != null) {
                            _codeController.text = data!.text!;
                          }
                        },
                        tooltip: '粘贴',
                      ),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitCode(),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _submitCode,
                    icon: const Icon(Icons.check),
                    label: const Text('确认登录'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
