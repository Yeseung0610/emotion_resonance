import 'package:http/http.dart' as http;
import 'dart:convert';
import '../shared/models/stay_data.dart';
import '../shared/utils/logger.dart';

class ApiService {
  final String baseUrl;
  final String deviceId;

  ApiService({
    this.baseUrl = 'http://100.114.49.33:8080',
    this.deviceId = 'mobile_01',
  });

  /// Send corner stay time data to server
  ///
  /// Returns true if successful, false otherwise
  Future<bool> sendStayTimeData(Map<String, int> cornerTimes) async {
    try {
      final stayData = StayData(
        deviceId: deviceId,
        cornerTimes: cornerTimes,
      );

      final response = await http.post(
        Uri.parse('$baseUrl/api/staytime'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(stayData.toJson()),
      );

      if (response.statusCode == 200) {
        Logger.success('Stay time data sent successfully', tag: 'API');
        return true;
      } else {
        Logger.error(
          'Failed to send data. Status: ${response.statusCode}',
          tag: 'API',
        );
        return false;
      }
    } catch (e) {
      Logger.error('Error sending stay time data: $e', tag: 'API');
      return false;
    }
  }

  /// Get all stay time data from server
  Future<Map<String, Map<String, int>>?> getStayTimeData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/staytime'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data.map(
          (key, value) => MapEntry(
            key,
            Map<String, int>.from(value as Map),
          ),
        );
      } else {
        Logger.error(
          'Failed to get data. Status: ${response.statusCode}',
          tag: 'API',
        );
        return null;
      }
    } catch (e) {
      Logger.error('Error getting stay time data: $e', tag: 'API');
      return null;
    }
  }
}
