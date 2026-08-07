import 'api_client.dart';

class TuyaApi {
  static Future<Map<String, dynamic>?> getCredentials() async {
    try {
      final userId = await ApiClient.getUserId();
      if (userId == null) return null;

      final response = await ApiClient.instance.get('/api/credentials/tuya/$userId');
      if (response.statusCode == 200 && response.data != null) {
        return {
          'clientId': response.data['clientId'],
          'clientSecret': response.data['clientSecret'],
          'deviceId': response.data['deviceId'],
          'baseUrl': response.data['baseUrl'],
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveCredentials(String clientId, String clientSecret,
      String deviceId, String baseUrl) async {
    final userId = await ApiClient.getUserId();
    if (userId == null) throw Exception('Not logged in');

    await ApiClient.instance.post('/api/credentials/tuya', data: {
      'userId': userId,
      'clientId': clientId,
      'clientSecret': clientSecret,
      'deviceId': deviceId,
      'baseUrl': baseUrl,
      'autoCutoffThresholdWatt': 5.0, // Default for now
    });
  }

  static Future<Map<String, dynamic>> getDeviceStatus() async {
    try {
      final userId = await ApiClient.getUserId();
      if (userId == null) return {'error': 'User not logged in'};

      final response = await ApiClient.instance.get('/api/tuya/status/$userId');
      if (response.statusCode == 200 && response.data != null) {
        if (response.data['success'] == true) {
            if (response.data['data'] != null) {
                final d = response.data['data'];
                if (d['success'] == false) {
                    return {'error': d['msg'] ?? 'Tuya API Error'};
                }
                if (d['result'] != null) {
                    return {'status': d['result']};
                }
            } else if (response.data['result'] != null) {
               return {'status': response.data['result']};
            }
        }
      }
      return {'error': 'Kredensial atau format salah'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<bool> sendCommand(List<Map<String, dynamic>> commands) async {
    try {
      final userId = await ApiClient.getUserId();
      if (userId == null) return false;

      // Extract the first command's value to determine if turning on or off
      if (commands.isEmpty) return false;
      final action = commands.first['value'] == true ? 'on' : 'off';

      final response = await ApiClient.instance.post('/api/tuya/control', data: {
        'userId': userId,
        'action': action,
        'delay': 0,
      });

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
