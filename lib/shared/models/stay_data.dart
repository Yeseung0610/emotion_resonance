/// Model for corner stay time data
class StayData {
  final String deviceId;
  final Map<String, int> cornerTimes;

  StayData({
    required this.deviceId,
    required this.cornerTimes,
  });

  /// Create from JSON
  factory StayData.fromJson(Map<String, dynamic> json) {
    return StayData(
      deviceId: json['device_id'] as String,
      cornerTimes: Map<String, int>.from(json['corner_times'] as Map),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'corner_times': cornerTimes,
    };
  }

  /// Copy with new values
  StayData copyWith({
    String? deviceId,
    Map<String, int>? cornerTimes,
  }) {
    return StayData(
      deviceId: deviceId ?? this.deviceId,
      cornerTimes: cornerTimes ?? this.cornerTimes,
    );
  }
}

/// Corner positions enum
enum Corner {
  topLeft('top-left'),
  topRight('top-right'),
  bottomLeft('bottom-left'),
  bottomRight('bottom-right');

  final String value;
  const Corner(this.value);

  static Corner fromString(String value) {
    return Corner.values.firstWhere(
      (corner) => corner.value == value,
      orElse: () => Corner.topLeft,
    );
  }
}
