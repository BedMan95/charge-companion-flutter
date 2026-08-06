import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../db/database_helper.dart';

class TuyaApi {
  static Future<Map<String, String>?> getCredentials() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('tuya_credentials', limit: 1);
    if (result.isNotEmpty) {
      return {
        'clientId': result.first['client_id'] as String,
        'clientSecret': result.first['client_secret'] as String,
        'deviceId': result.first['device_id'] as String,
        'baseUrl': result.first['base_url'] as String,
      };
    }
    return null;
  }

  static Future<void> saveCredentials(String clientId, String clientSecret,
      String deviceId, String baseUrl) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('tuya_credentials');
    await db.insert('tuya_credentials', {
      'client_id': clientId,
      'client_secret': clientSecret,
      'device_id': deviceId,
      'base_url': baseUrl,
    });
  }

  static String _generateSignature(String clientId, String clientSecret,
      String t, String nonce, String stringToSign,
      {String? accessToken}) {
    final str = clientId + (accessToken ?? '') + t + nonce + stringToSign;
    final hmac = Hmac(sha256, utf8.encode(clientSecret));
    final digest = hmac.convert(utf8.encode(str));
    return digest.toString().toUpperCase();
  }

  static Future<String?> _getToken(Map<String, String> creds) async {
    final t = DateTime.now().millisecondsSinceEpoch.toString();
    const nonce = '';
    const stringToSign =
        'GET\ne3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\n\n/v1.0/token?grant_type=1';

    final sign = _generateSignature(
        creds['clientId']!, creds['clientSecret']!, t, nonce, stringToSign);

    final response = await http.get(
      Uri.parse('${creds['baseUrl']}/v1.0/token?grant_type=1'),
      headers: {
        'client_id': creds['clientId']!,
        'sign': sign,
        't': t,
        'sign_method': 'HMAC-SHA256',
        'nonce': nonce,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data['result']['access_token'];
      } else {
        throw Exception('Tuya API Error (Token): ${data['msg']}');
      }
    } else {
      throw Exception(
          'HTTP Error (Token): ${response.statusCode} - ${response.body}');
    }
  }

  static Future<Map<String, dynamic>?> getDeviceStatus() async {
    final creds = await getCredentials();
    if (creds == null) return null;

    final token = await _getToken(creds);
    if (token == null) return null;

    final t = DateTime.now().millisecondsSinceEpoch.toString();
    const nonce = '';
    final path = '/v1.0/iot-03/devices/${creds['deviceId']}/status';
    final stringToSign =
        'GET\ne3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\n\n$path';

    final sign = _generateSignature(
        creds['clientId']!, creds['clientSecret']!, t, nonce, stringToSign,
        accessToken: token);

    final response = await http.get(
      Uri.parse('${creds['baseUrl']}$path'),
      headers: {
        'client_id': creds['clientId']!,
        'access_token': token,
        'sign': sign,
        't': t,
        'sign_method': 'HMAC-SHA256',
        'nonce': nonce,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return {'status': data['result']};
      } else {
        throw Exception('Tuya API Error (Status): ${data['msg']}');
      }
    } else {
      throw Exception(
          'HTTP Error (Status): ${response.statusCode} - ${response.body}');
    }
  }

  static Future<bool> sendCommand(List<Map<String, dynamic>> commands) async {
    final creds = await getCredentials();
    if (creds == null) return false;

    final token = await _getToken(creds);
    if (token == null) return false;

    final t = DateTime.now().millisecondsSinceEpoch.toString();
    const nonce = '';
    final path = '/v1.0/iot-03/devices/${creds['deviceId']}/commands';
    final bodyStr = jsonEncode({'commands': commands});

    final bodyHash = sha256.convert(utf8.encode(bodyStr)).toString();
    final stringToSign = 'POST\n$bodyHash\n\n$path';

    final sign = _generateSignature(
        creds['clientId']!, creds['clientSecret']!, t, nonce, stringToSign,
        accessToken: token);

    final response = await http.post(
      Uri.parse('${creds['baseUrl']}$path'),
      headers: {
        'client_id': creds['clientId']!,
        'access_token': token,
        'sign': sign,
        't': t,
        'sign_method': 'HMAC-SHA256',
        'nonce': nonce,
        'Content-Type': 'application/json',
      },
      body: bodyStr,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }
}
