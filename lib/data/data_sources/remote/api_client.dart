import 'package:dio/dio.dart';
import 'package:manus/core/error/exception.dart';
import 'package:manus/values/network_constants.dart';

import 'package:talker_dio_logger/talker_dio_logger.dart';

class ApiClient {
  final Dio _dio;

  ApiClient({required Dio dio}) : _dio = dio {
    _dio.options = BaseOptions(
      baseUrl: NetworkConstants.baseUrl,
      connectTimeout: const Duration(
        seconds: NetworkConstants.connectTimeoutSeconds,
      ),
      receiveTimeout: const Duration(
        seconds: NetworkConstants.receiveTimeoutSeconds,
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio.interceptors.addAll([
      TalkerDioLogger(
        settings: const TalkerDioLoggerSettings(
          printRequestData: true,
          printResponseData: true,
          printRequestHeaders: true,
        ),
      ),
      // Add AuthInterceptor here if needed later
    ]);
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ServerException(message: 'Connection Timeout', statusCode: 408);
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = _extractErrorMessage(error);
        return ServerException(message: message, statusCode: statusCode);
      case DioExceptionType.connectionError:
        return ServerException(
          message: 'No Internet Connection',
          statusCode: 503,
        );
      default:
        return ServerException(
          message: 'Something went wrong',
          statusCode: 500,
        );
    }
  }

  String _extractErrorMessage(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ?? 'Something went wrong';
    }

    if (data is String && data.isNotEmpty) {
      return data;
    }

    return error.message ?? 'Something went wrong';
  }
}
