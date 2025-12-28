import 'package:dio/dio.dart';
import 'package:rank_hub/modules/lxns/services/lxns_api_response.dart';

/// LXNS API 异常
class LxnsApiException implements Exception {
  final String message;
  final int? code;
  final dynamic originalError;

  LxnsApiException({required this.message, this.code, this.originalError});

  @override
  String toString() => 'LxnsApiException: $message (code: $code)';
}

/// LXNS 平台 API 服务
/// 为新架构提供的 API 调用封装
class LxnsApiService {
  static const String baseUrl = 'https://maimai.lxns.net';
  static const int defaultVersion = 25000;

  final Dio _dio;

  LxnsApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              headers: {'User-Agent': 'RankHub/1.0.0'},
            ),
          );

  // ==================== 曲目相关 API ====================

  /// 获取曲目列表及相关数据
  ///
  /// 返回原始 API 响应数据，包含：
  /// - songs: 曲目列表的 JSON 数组
  /// - genres: 曲风列表的 JSON 数组
  /// - versions: 版本列表的 JSON 数组
  Future<Map<String, dynamic>> getSongList({
    int version = defaultVersion,
    bool notes = false,
    String? accessToken,
  }) async {
    try {
      final options = accessToken != null
          ? Options(headers: {'Authorization': 'Bearer $accessToken'})
          : null;

      final response = await _dio.get(
        '/api/v0/maimai/song/list',
        queryParameters: {'version': version, 'notes': notes},
        options: options,
      );

      final apiResponse = LxnsApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        dataParser: (data) => data as Map<String, dynamic>,
      );

      if (!apiResponse.success) {
        throw LxnsApiException(
          message: apiResponse.message ?? '获取曲目列表失败',
          code: apiResponse.code,
        );
      }

      // 返回原始数据，由调用方负责转换
      return apiResponse.data!;
    } on DioException catch (e) {
      throw LxnsApiException(
        message: '网络请求失败: ${e.message}',
        code: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  // ==================== 玩家成绩相关 API ====================

  /// 获取玩家成绩列表
  ///
  /// 返回原始 API 响应数据 (List<dynamic>)
  Future<List<dynamic>> getPlayerScores({
    required String accessToken,
    int version = defaultVersion,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v0/user/maimai/player/scores',
        queryParameters: {'version': version},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      final apiResponse = LxnsApiResponse<List>.fromJson(
        response.data,
        dataParser: (data) => data as List,
      );

      if (!apiResponse.success) {
        throw LxnsApiException(
          message: apiResponse.message ?? '获取玩家成绩失败',
          code: apiResponse.code,
        );
      }

      return apiResponse.data!;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw LxnsApiException(
          message: '玩家档案不存在,请前往落雪咖啡屋官网同步一次数据来创建玩家档案',
          code: 404,
          originalError: e,
        );
      }
      throw LxnsApiException(
        message: '网络请求失败: ${e.message}',
        code: e.response?.statusCode,
        originalError: e,
      );
    }
  }

  /// 获取玩家 Best 50 成绩
  Future<Map<String, dynamic>> getPlayerBest50({
    required String accessToken,
    int version = defaultVersion,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v0/user/maimai/player/bests',
        queryParameters: {'version': version},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      final apiResponse = LxnsApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        dataParser: (data) => data as Map<String, dynamic>,
      );

      if (!apiResponse.success) {
        throw LxnsApiException(
          message: apiResponse.message ?? '获取 Best 50 失败',
          code: apiResponse.code,
        );
      }

      return apiResponse.data!;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw LxnsApiException(
          message: '玩家档案不存在,请前往落雪咖啡屋官网同步一次数据来创建玩家档案',
          code: 404,
          originalError: e,
        );
      }
      throw LxnsApiException(
        message: '网络请求失败: ${e.message}',
        code: e.response?.statusCode,
        originalError: e,
      );
    }
  }
}
