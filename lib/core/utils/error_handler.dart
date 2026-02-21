import 'package:dio/dio.dart';
import 'dart:io';

class ErrorHandler {
  static Future<String> getErrorMessage(dynamic error) async {
    if (error is DioException) {
      // Check for actual network errors (no response from server)
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return "Connection timeout. Please try again.";
      }
      
      // Check for connection errors
      if (error.type == DioExceptionType.connectionError) {
        return "No internet connection. Please check your network.";
      }
      
      if (error.type == DioExceptionType.unknown) {
        if (error.error is SocketException) {
          return "No internet connection. Please check your network.";
        }
        return error.message ?? "Network error. Please try again.";
      }
      
      // If we got a response, it means internet is working
      final statusCode = error.response?.statusCode;
      
      if (statusCode == null) {
        return "Network error. Please check your connection.";
      }
      
      // Try to get message from response data first
      final responseMessage = error.response?.data?['message'];
      
      switch (statusCode) {
        case 400:
          return responseMessage ?? "Invalid request. Please check your input.";
        case 401:
          return responseMessage ?? "Session expired. Please login again.";
        case 403:
          return responseMessage ?? "Access denied. You don't have permission.";
        case 404:
          return responseMessage ?? "Resource not found. Please try again.";
        case 429:
          return "Too many requests. Please wait and try again.";
        case 500:
          return "Server error. Please try again later.";
        case 502:
          return "Bad gateway. Please try again later.";
        case 503:
          return "Service unavailable. Please try again later.";
        case 504:
          return "Gateway timeout. Please try again.";
        default:
          return responseMessage ?? "Something went wrong. Please try again.";
      }
    }
    
    return "An unexpected error occurred. Please try again.";
  }
}
