import 'dart:async';
import '../../shared/models/stay_data.dart';

/// Service to track time spent in each corner
class TimeTracker {
  final Map<String, int> _cornerTimes = {
    Corner.topLeft.value: 0,
    Corner.topRight.value: 0,
    Corner.bottomLeft.value: 0,
    Corner.bottomRight.value: 0,
  };

  Corner? _currentCorner;
  Timer? _trackingTimer;
  DateTime? _cornerStartTime;

  Map<String, int> get cornerTimes => Map.from(_cornerTimes);
  Corner? get currentCorner => _currentCorner;

  /// Start tracking time for a specific corner
  void startTracking(Corner corner) {
    if (_currentCorner == corner) {
      return; // Already tracking this corner
    }

    // Stop current tracking if any
    _stopCurrentTracking();

    // Start new tracking
    _currentCorner = corner;
    _cornerStartTime = DateTime.now();

    // Update timer every second
    _trackingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_cornerStartTime != null) {
        _cornerTimes[corner.value] = (_cornerTimes[corner.value] ?? 0) + 1;
      }
    });
  }

  /// Stop tracking current corner
  void stopTracking() {
    _stopCurrentTracking();
  }

  void _stopCurrentTracking() {
    if (_currentCorner != null && _cornerStartTime != null) {
      // Already tracked by periodic timer, no need to add elapsed time again
    }

    _trackingTimer?.cancel();
    _trackingTimer = null;
    _currentCorner = null;
    _cornerStartTime = null;
  }

  /// Reset all times
  void reset() {
    stopTracking();
    _cornerTimes.forEach((key, _) {
      _cornerTimes[key] = 0;
    });
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
  }

  /// Determine corner based on position in frame
  /// x, y are normalized coordinates (0.0 to 1.0)
  static Corner getCornerFromPosition(double x, double y) {
    if (y < 0.5) {
      // Top half
      return x < 0.5 ? Corner.topLeft : Corner.topRight;
    } else {
      // Bottom half
      return x < 0.5 ? Corner.bottomLeft : Corner.bottomRight;
    }
  }
}
