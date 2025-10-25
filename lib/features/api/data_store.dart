import '../../shared/models/stay_data.dart';

/// In-memory data store for stay time data
class DataStore {
  static final DataStore _instance = DataStore._internal();
  factory DataStore() => _instance;
  DataStore._internal();

  /// Store data by device ID
  final Map<String, Map<String, int>> _stayData = {};

  /// Update stay data for a device
  void updateStayData(StayData data) {
    _stayData[data.deviceId] = data.cornerTimes;
  }

  /// Get stay data for a specific device
  Map<String, int>? getStayData(String deviceId) {
    return _stayData[deviceId];
  }

  /// Get all stay data
  Map<String, Map<String, int>> getAllStayData() {
    return Map.from(_stayData);
  }

  /// Clear all data
  void clear() {
    _stayData.clear();
  }

  /// Remove data for a specific device
  void removeDevice(String deviceId) {
    _stayData.remove(deviceId);
  }
}
