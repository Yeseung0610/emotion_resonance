import 'dart:typed_data';
import 'package:camera/camera.dart';
import '../../shared/models/stay_data.dart';
import '../../shared/utils/logger.dart';

/// Simple motion detector based on pixel changes
class MotionDetector {
  Uint8List? _previousFrame;
  int _frameWidth = 0;
  int _frameHeight = 0;

  /// Detect motion in camera image and return the corner with most activity
  /// Returns null if processing or no significant motion
  Corner? detectMotion(CameraImage image) {
    try {
      // Get luminance data (Y plane for YUV format)
      if (image.planes.isEmpty) return null;

      final currentFrame = image.planes[0].bytes;
      _frameWidth = image.width;
      _frameHeight = image.height;

      // First frame - just store it
      if (_previousFrame == null) {
        _previousFrame = Uint8List.fromList(currentFrame);
        return null;
      }

      // Calculate motion in each corner
      final motionScores = _calculateCornerMotion(currentFrame);

      // Update previous frame
      _previousFrame = Uint8List.fromList(currentFrame);

      // Find corner with most motion
      Corner? maxCorner;
      int maxMotion = 0;

      motionScores.forEach((corner, motion) {
        if (motion > maxMotion && motion > 500) { // 임계값
          maxMotion = motion;
          maxCorner = corner;
        }
      });

      if (maxCorner != null) {
        Logger.success(
          'Motion detected in ${_getCornerName(maxCorner!)} | '
          'Score: $maxMotion | All: ${motionScores.entries.map((e) => '${_getCornerName(e.key)}=${e.value}').join(', ')}',
          tag: 'MOTION',
        );
      }

      return maxCorner;
    } catch (e) {
      Logger.error('Error detecting motion: $e', tag: 'MOTION');
      return null;
    }
  }

  /// Calculate motion score for each corner
  Map<Corner, int> _calculateCornerMotion(Uint8List currentFrame) {
    final scores = <Corner, int>{
      Corner.topLeft: 0,
      Corner.topRight: 0,
      Corner.bottomLeft: 0,
      Corner.bottomRight: 0,
    };

    final halfWidth = _frameWidth ~/ 2;
    final halfHeight = _frameHeight ~/ 2;

    // 샘플링: 모든 픽셀 체크하면 느리므로 10픽셀마다 체크
    for (int y = 0; y < _frameHeight; y += 10) {
      for (int x = 0; x < _frameWidth; x += 10) {
        final index = y * _frameWidth + x;

        if (index >= currentFrame.length || index >= _previousFrame!.length) {
          continue;
        }

        // 픽셀 차이 계산
        final diff = (currentFrame[index] - _previousFrame![index]).abs();

        // 어느 코너에 속하는지 판단
        Corner corner;
        if (y < halfHeight) {
          corner = x < halfWidth ? Corner.topLeft : Corner.topRight;
        } else {
          corner = x < halfWidth ? Corner.bottomLeft : Corner.bottomRight;
        }

        scores[corner] = scores[corner]! + diff;
      }
    }

    return scores;
  }

  String _getCornerName(Corner corner) {
    switch (corner) {
      case Corner.topLeft:
        return 'TopLeft';
      case Corner.topRight:
        return 'TopRight';
      case Corner.bottomLeft:
        return 'BottomLeft';
      case Corner.bottomRight:
        return 'BottomRight';
    }
  }

  /// Reset previous frame
  void reset() {
    _previousFrame = null;
  }

  /// Dispose resources
  void dispose() {
    _previousFrame = null;
  }
}
