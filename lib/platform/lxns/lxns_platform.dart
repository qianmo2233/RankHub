import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rank_hub/core/platform.dart';
import 'package:rank_hub/core/account.dart' as core;
import 'package:rank_hub/core/platform_id.dart';
import 'package:rank_hub/platform/lxns/lxns_login_page.dart';
import 'package:rank_hub/platform/lxns/lxns_credential_provider.dart';

/// 落雪咖啡屋平台实现
/// 使用 OAuth2 + PKCE 授权流程
class LxnsPlatform implements Platform {
  static const String baseUrl = 'https://maimai.lxns.net';
  static const String iconUrl = 'https://maimai.lxns.net/favicon.webp';
  static const String backgroundUrl =
      'https://maimai.lxns.net/logo_background.webp';

  @override
  PlatformId get id => const PlatformId('lxns');

  @override
  String get name => '落雪咖啡屋';

  @override
  ImageProvider get icon => const CachedNetworkImageProvider(iconUrl);

  final LxnsCredentialProvider _credentialProvider = LxnsCredentialProvider();

  @override
  Widget buildLoginPage() {
    return const LxnsLoginPage();
  }

  @override
  Future<core.Account> login() async {
    // 登录逻辑由 LxnsLoginPage 处理，这里不应该被直接调用
    throw UnimplementedError('登录应通过 buildLoginPage() 返回的页面完成');
  }

  @override
  Future<core.Account> refresh(core.Account account) async {
    return await _credentialProvider.refreshCredential(account);
  }

  @override
  Future<bool> validate(core.Account account) async {
    return await _credentialProvider.validateCredential(account);
  }
}
