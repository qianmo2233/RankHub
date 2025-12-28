import 'package:dio/dio.dart';
import 'package:rank_hub/core/account.dart' as core;
import 'package:rank_hub/core/credential_provider.dart';
import 'package:rank_hub/core/platform_id.dart';
import 'package:rank_hub/modules/lxns/services/lxns_api_response.dart';

/// 落雪咖啡屋凭据提供者
/// 使用 OAuth2 + PKCE 授权，支持自动刷新 token
class LxnsCredentialProvider extends OAuth2CredentialProvider {
  static const String baseUrl = 'https://maimai.lxns.net';
  static const String clientId = 'd7a8e3dc-0e08-43b1-ac08-7e4b2b4574bd';

  final Dio _dio = Dio();

  @override
  PlatformId get platformId => const PlatformId('lxns');

  @override
  Future<Map<String, dynamic>> requestTokenRefresh(String refreshToken) async {
    print('🔄 开始刷新 token...');
    print('📤 请求 URL: $baseUrl/api/v0/oauth/token');

    try {
      final response = await _dio.post(
        '$baseUrl/api/v0/oauth/token',
        data: {
          'client_id': clientId,
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
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
          throw Exception('刷新 token 失败: ${apiResponse.message}');
        }

        final data = apiResponse.data!;
        final expiresIn = data['expires_in'] as int;

        print('✅ 刷新 token 成功');

        return {
          'access_token': data['access_token'],
          'refresh_token': data['refresh_token'],
          'expires_in': expiresIn,
        };
      }

      throw Exception('刷新 token 失败: HTTP ${response.statusCode}');
    } on DioException catch (dioException) {
      print('❌ 刷新 token 失败 (DioException):');
      print('   错误类型: ${dioException.type}');
      print('   响应状态码: ${dioException.response?.statusCode}');
      print('   响应数据: ${dioException.response?.data}');
      throw Exception('刷新 token 失败: ${dioException.message}');
    }
  }

  @override
  Future<bool> validateCredential(core.Account account) async {
    final accessToken = account.credentials['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      return false;
    }

    try {
      final response = await _dio.get(
        '$baseUrl/api/v0/user/profile',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        final apiResponse = LxnsApiResponse.fromJson(response.data);
        return apiResponse.success;
      }
      return false;
    } catch (e) {
      print('验证 token 失败: $e');
      return false;
    }
  }

  @override
  Future<void> createCredential(
    core.Account account,
    Map<String, dynamic> data,
  ) async {
    // OAuth2 凭据已经在 data 中，直接设置到 credentials
    // 不需要额外处理
  }

  @override
  Future<void> revokeCredential(core.Account account) async {
    // LXNS 平台暂不支持撤销凭据的 API
    // 仅清空本地凭据数据即可
  }
}
