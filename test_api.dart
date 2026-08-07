import 'dart:convert';
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(BaseOptions(
    baseUrl: 'http://127.0.0.1:8787',
  ));

  // login
  final loginRes = await dio.post('/api/auth/login', data: {
    'email': 'witzardyourboss@gmail.com',
    'password': 'password123',
  });
  final token = loginRes.data['token'];
  final userId = loginRes.data['user']['id'];

  print('Login: $token');

  // get status
  try {
    final statusRes = await dio.get('/api/tuya/status/$userId', options: Options(
      headers: {
        'Authorization': 'Bearer $token'
      }
    ));
    print('Status Response: ${jsonEncode(statusRes.data)}');
  } catch (e) {
    if (e is DioException) {
      print('Status Error: ${e.response?.statusCode} - ${e.response?.data}');
    } else {
      print('Status Error: $e');
    }
  }
}
