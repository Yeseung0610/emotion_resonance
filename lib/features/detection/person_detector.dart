import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/foundation.dart' show WriteBuffer;
import '../../shared/models/stay_data.dart';
import '../../shared/utils/logger.dart';

class PersonDetector {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
    ),
  );

  bool _isProcessing = false;
  CameraDescription? _camera;

  /// Set camera description for proper rotation handling
  void setCamera(CameraDescription camera) {
    _camera = camera;
  }

  /// Detect person in camera image and return their position
  /// Returns null if no person detected or processing
  Future<DetectionResult?> detectPerson(CameraImage image) async {
    if (_isProcessing) return null;

    _isProcessing = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return null;
      }

      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isEmpty) {
        _isProcessing = false;
        return null;
      }

      // Get the first detected pose
      final pose = poses.first;

      // Calculate center position from pose landmarks
      final center = _calculatePoseCenter(pose);

      if (center == null) {
        _isProcessing = false;
        return null;
      }

      // Normalize coordinates (0.0 to 1.0)
      final normalizedX = center.dx / image.width;
      final normalizedY = center.dy / image.height;

      final confidence = _calculateConfidence(pose);

      // ✅ 감지 성공 로그 (상세 정보)
      _logDetectionSuccess(pose, normalizedX, normalizedY, confidence);

      _isProcessing = false;

      return DetectionResult(
        x: normalizedX,
        y: normalizedY,
        confidence: confidence,
      );
    } catch (e) {
      // 오류 로그 제거 (너무 많이 출력됨)
      _isProcessing = false;
      return null;
    }
  }

  /// Convert CameraImage to InputImage for ML Kit
  InputImage? _convertCameraImage(CameraImage image) {
    try {
      // Get proper rotation
      final rotation = _getRotation();

      // Get image format
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) {
        Logger.error('Unknown image format: ${image.format.raw}', tag: 'DETECTOR');
        return null;
      }

      // Create metadata
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      // Convert image bytes
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );
    } catch (e) {
      // 오류 로그 제거 (너무 많이 출력됨)
      return null;
    }
  }

  /// Get the rotation of the image based on device orientation and camera sensor
  InputImageRotation _getRotation() {
    if (_camera == null) {
      return InputImageRotation.rotation0deg;
    }

    // For most Android devices with back camera
    final sensorOrientation = _camera!.sensorOrientation;

    // Map sensor orientation to InputImageRotation
    switch (sensorOrientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  /// Calculate the center point of the detected pose
  Offset? _calculatePoseCenter(Pose pose) {
    final landmarks = pose.landmarks;

    // Use key body landmarks to calculate center
    final nose = landmarks[PoseLandmarkType.nose];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];

    // Collect valid landmark points
    final points = <Offset>[];

    if (nose != null) points.add(Offset(nose.x, nose.y));
    if (leftShoulder != null) points.add(Offset(leftShoulder.x, leftShoulder.y));
    if (rightShoulder != null) points.add(Offset(rightShoulder.x, rightShoulder.y));
    if (leftHip != null) points.add(Offset(leftHip.x, leftHip.y));
    if (rightHip != null) points.add(Offset(rightHip.x, rightHip.y));

    if (points.isEmpty) return null;

    // Calculate average position
    double avgX = 0;
    double avgY = 0;

    for (final point in points) {
      avgX += point.dx;
      avgY += point.dy;
    }

    avgX /= points.length;
    avgY /= points.length;

    return Offset(avgX, avgY);
  }

  /// Calculate confidence score from pose landmarks
  /// Returns the average likelihood of key body parts
  double _calculateConfidence(Pose pose) {
    // 주요 랜드마크만 사용 (더 안정적)
    final keyLandmarks = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    ];

    double totalConfidence = 0;
    int count = 0;

    for (final type in keyLandmarks) {
      final landmark = pose.landmarks[type];
      if (landmark != null) {
        totalConfidence += landmark.likelihood;
        count++;
      }
    }

    final avgConfidence = count > 0 ? totalConfidence / count : 0.0;

    return avgConfidence;
  }

  /// Log successful detection with detailed information
  void _logDetectionSuccess(Pose pose, double x, double y, double confidence) {
    final landmarks = pose.landmarks;

    // 각 주요 랜드마크의 likelihood
    final landmarkInfo = <String, String>{};

    final keyTypes = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    ];

    for (final type in keyTypes) {
      final landmark = landmarks[type];
      if (landmark != null) {
        final name = type.toString().split('.').last;
        landmarkInfo[name] = landmark.likelihood.toStringAsFixed(2);
      }
    }

    Logger.success(
      'DETECTED! Confidence: ${confidence.toStringAsFixed(2)} | '
      'Position: (${(x * 100).toStringAsFixed(0)}%, ${(y * 100).toStringAsFixed(0)}%) | '
      'Landmarks: ${landmarkInfo.length}/5',
      tag: 'DETECT',
    );

    // 상세 랜드마크 정보
    Logger.info(
      'Landmarks: ${landmarkInfo.entries.map((e) => '${e.key}=${e.value}').join(', ')}',
      tag: 'DETECT',
    );
  }

  /// Dispose resources
  void dispose() {
    _poseDetector.close();
  }
}

/// Result of person detection
class DetectionResult {
  final double x; // Normalized X position (0.0 - 1.0)
  final double y; // Normalized Y position (0.0 - 1.0)
  final double confidence; // Detection confidence (0.0 - 1.0)

  DetectionResult({
    required this.x,
    required this.y,
    required this.confidence,
  });

  /// Get corner based on position
  Corner getCorner() {
    if (y < 0.5) {
      // Top half
      return x < 0.5 ? Corner.topLeft : Corner.topRight;
    } else {
      // Bottom half
      return x < 0.5 ? Corner.bottomLeft : Corner.bottomRight;
    }
  }

  @override
  String toString() {
    return 'DetectionResult(x: ${x.toStringAsFixed(2)}, y: ${y.toStringAsFixed(2)}, confidence: ${confidence.toStringAsFixed(2)})';
  }
}
