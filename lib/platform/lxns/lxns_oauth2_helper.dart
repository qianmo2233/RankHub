import 'package:dio/dio.dart';
import 'package:rank_hub/utils/pkce_helper.dart';
import 'package:rank_hub/modules/lxns/services/lxns_api_response.dart';

/// OAuth2 授权结果
class OAuth2AuthResult {
  final String externalId;
  final Map<String, dynamic> credentials;
  final String? displayName;
  final String? avatarUrl;

  OAuth2AuthResult({
    required this.externalId,
    required this.credentials,
    this.displayName,
    this.avatarUrl,
  });
}

/// LXNS OAuth2 授权助手
class LxnsOAuth2Helper {
  static const String baseUrl = 'https://maimai.lxns.net';
  static const String iconUrl = 'https://maimai.lxns.net/favicon.webp';
  static const String clientId = 'd7a8e3dc-0e08-43b1-ac08-7e4b2b4574bd';
  static const String redirectUri = 'https://rankhub.kamitsubaki.city/callback';
  static const String scope =
      'read_user_profile read_player read_user_token write_player';

  // 手动输入授权码配置
  static const String manualClientId = '2f8e94e4-1faf-4213-bfbc-0aaf55e71a86';
  static const String manualRedirectUri = 'urn:ietf:wg:oauth:2.0:oob';

  final Dio _dio = Dio();

  /// 生成授权 URL 和 PKCE 参数
  Map<String, String> generateAuthUrl({bool manual = false}) {
    final pkcePair = PkceHelper.generatePkcePair();
    final codeVerifier = pkcePair['code_verifier']!;
    final codeChallenge = pkcePair['code_challenge']!;
    final state = DateTime.now().millisecondsSinceEpoch.toString();

    final effectiveClientId = manual ? manualClientId : clientId;
    final effectiveRedirectUri = manual ? manualRedirectUri : redirectUri;

    final authUrl =
        '$baseUrl/oauth/authorize?'
        'response_type=code&'
        'client_id=$effectiveClientId&'
        'redirect_uri=${Uri.encodeComponent(effectiveRedirectUri)}&'
        'scope=${Uri.encodeComponent(scope)}&'
        'code_challenge=$codeChallenge&'
        'code_challenge_method=S256&'
        'state=$state';

    return {
      'auth_url': authUrl,
      'code_verifier': codeVerifier,
      'state': state,
      'redirect_uri': effectiveRedirectUri,
      'client_id': effectiveClientId,
    };
  }

  /// 使用授权码交换访问令牌
  Future<Map<String, dynamic>?> exchangeCodeForToken({
    required String code,
    required String codeVerifier,
    required String clientId,
    required String redirectUri,
  }) async {
    print('🔄 开始交换授权码...');
    print('📤 请求 URL: $baseUrl/api/v0/oauth/token');

    try {
      final response = await _dio.post(
        '$baseUrl/api/v0/oauth/token',
        data: {
          'client_id': clientId,
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
          'code_verifier': codeVerifier,
        },
        options: Options(contentType: Headers.jsonContentType),
      );

      print('📥 响应状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        final apiResponse = LxnsApiResponse<Map<String, dynamic>>.fromJson(
          response.data,
          dataParser: (data) => data as Map<String, dynamic>,
        );

        if (!apiResponse.success) {
          print('❌ API 返回失败: ${apiResponse.message}');
          return null;
        }

        final data = apiResponse.data!;
        final tokenData = {
          'access_token': data['access_token'],
          'refresh_token': data['refresh_token'],
          'token_expiry': DateTime.now()
              .add(Duration(seconds: data['expires_in'] as int))
              .toIso8601String(),
          'scope': data['scope'],
        };

        print('✅ 交换 token 成功');
        return tokenData;
      }
    } on DioException catch (dioException) {
      print('❌ 交换 token 失败 (DioException):');
      print('   错误类型: ${dioException.type}');
      print('   响应数据: ${dioException.response?.data}');
    } catch (e) {
      print('❌ 交换 token 失败: $e');
    }
    return null;
  }

  /// 获取用户信息
  Future<OAuth2AuthResult?> fetchUserInfo(
    Map<String, dynamic> tokenData,
  ) async {
    final accessToken = tokenData['access_token'] as String?;
    if (accessToken == null) {
      return null;
    }

    try {
      print('📤 获取用户信息...');
      final response = await _dio.get(
        '$baseUrl/api/v0/user/profile',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      print('📥 响应: ${response.data}');

      if (response.statusCode == 200) {
        final apiResponse = LxnsApiResponse<Map<String, dynamic>>.fromJson(
          response.data,
          dataParser: (data) => data as Map<String, dynamic>,
        );

        if (!apiResponse.success) {
          print('❌ API 返回失败: ${apiResponse.message}');
          return null;
        }

        final profileData = apiResponse.data!;
        final userId = profileData['id'];
        final userName = profileData['name'];

        print('✅ 获取用户信息成功: $userName (ID: $userId)');

        return OAuth2AuthResult(
          externalId: userId.toString(),
          credentials: tokenData,
          displayName: userName ?? 'lxns_user',
          avatarUrl: iconUrl,
        );
      }
    } catch (e) {
      print('❌ 获取用户信息失败: $e');
    }
    return null;
  }
}
