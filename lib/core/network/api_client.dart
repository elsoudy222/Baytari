import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../errors/exceptions.dart';

/// Central Dio client. All HTTP traffic in the app goes through this class
/// (from data sources only — never from widgets or Cubits).
///
/// There is no REST base URL in M0: Supabase is the backend and it is
/// accessed through the Supabase client, not through Dio. Dio is kept
/// configured and ready for any future REST endpoints, and its error
/// mapping is unit-testable through [mapError].
class ApiClient {
  ApiClient({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options
      ..connectTimeout = ApiConstants.connectTimeout
      ..receiveTimeout = ApiConstants.receiveTimeout
      ..sendTimeout = ApiConstants.sendTimeout
      ..headers = <String, String>{
        'Content-Type': ApiConstants.jsonContentType,
      };
    _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  final Dio _dio;

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw mapError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw mapError(e);
    }
  }

  /// Maps a [DioException] to a plain [AppException]. Kept public and
  /// static so it can be unit tested without a network call.
  static AppException mapError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException('Network connection failed.');
      case DioExceptionType.badResponse:
        final int? statusCode = error.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          return const AuthException('Not authorized.');
        }
        return ServerException(
          'Server error${statusCode == null ? '' : ' ($statusCode)'}.',
        );
      case DioExceptionType.cancel:
        return const AppException('Request was cancelled.');
      case DioExceptionType.badCertificate:
        return const NetworkException('Bad certificate.');
      case DioExceptionType.transformTimeout:
        return const NetworkException('Response transformation timed out.');
      case DioExceptionType.unknown:
        return const NetworkException('Unknown network error.');
    }
  }
}
