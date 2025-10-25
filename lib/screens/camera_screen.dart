import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../services/api_service.dart';
import '../features/detection/time_tracker.dart';
import '../features/detection/motion_detector.dart';
import '../shared/models/stay_data.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraService _cameraService = CameraService();
  final ApiService _apiService = ApiService();
  final TimeTracker _timeTracker = TimeTracker();
  final MotionDetector _motionDetector = MotionDetector();

  bool _isInitialized = false;
  bool _isDetectionEnabled = true; // 기본값: 자동 모션 감지
  String? _message;
  Timer? _sendTimer;
  Corner? _lastDetectedCorner;

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    // Auto-send data every 5 seconds
    _sendTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _sendData();
    });
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _message = 'Initializing camera...';
    });

    final success = await _cameraService.initialize();

    setState(() {
      _isInitialized = success;
      _message = success ? null : 'Failed to initialize camera';
    });

    if (success) {
      // Start motion detection
      _startDetection();

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _message = _isDetectionEnabled
                ? 'Auto motion detection enabled'
                : 'Manual mode - Tap corners';
          });
        }
      });
    }
  }

  void _startDetection() {
    if (!_isDetectionEnabled) return;

    _cameraService.controller?.startImageStream((CameraImage image) {
      if (!_isDetectionEnabled) return;

      final corner = _motionDetector.detectMotion(image);

      if (corner != null && mounted) {
        setState(() {
          _lastDetectedCorner = corner;
          _timeTracker.startTracking(corner);
        });

        print('📍 Motion in: ${_getCornerName(corner)}');
      }
    });
  }

  void _stopDetection() {
    _cameraService.controller?.stopImageStream();
  }

  void _toggleDetection() {
    setState(() {
      _isDetectionEnabled = !_isDetectionEnabled;

      if (_isDetectionEnabled) {
        _message = 'Auto motion detection enabled';
        _motionDetector.reset(); // Reset previous frame
        _startDetection();
      } else {
        _message = 'Manual mode - Tap corners';
        _stopDetection();
        _timeTracker.stopTracking();
      }
    });
  }

  Future<void> _sendData() async {
    final cornerTimes = _timeTracker.cornerTimes;
    await _apiService.sendStayTimeData(cornerTimes);
  }

  void _onCornerTapped(Corner corner) {
    setState(() {
      _timeTracker.startTracking(corner);
      _message = 'Tracking: ${_getCornerName(corner)}';
    });
  }

  String _getCornerName(Corner corner) {
    switch (corner) {
      case Corner.topLeft:
        return 'Top Left';
      case Corner.topRight:
        return 'Top Right';
      case Corner.bottomLeft:
        return 'Bottom Left';
      case Corner.bottomRight:
        return 'Bottom Right';
    }
  }

  @override
  void dispose() {
    _sendTimer?.cancel();
    _stopDetection();
    _timeTracker.dispose();
    _motionDetector.dispose();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emotion Resonance Camera'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_isDetectionEnabled ? Icons.auto_fix_high : Icons.touch_app),
            onPressed: _toggleDetection,
            tooltip: _isDetectionEnabled ? 'Switch to Manual' : 'Switch to Auto',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _timeTracker.reset();
                _message = 'Times reset';
              });
            },
            tooltip: 'Reset times',
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendData,
            tooltip: 'Send data now',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          if (_isInitialized && _cameraService.controller != null)
            Center(
              child: CameraPreview(_cameraService.controller!),
            )
          else
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Interactive corner overlay (only in manual mode)
          if (_isInitialized && !_isDetectionEnabled)
            Positioned.fill(
              child: GridView.count(
                crossAxisCount: 2,
                children: [
                  _buildCornerButton(Corner.topLeft),
                  _buildCornerButton(Corner.topRight),
                  _buildCornerButton(Corner.bottomLeft),
                  _buildCornerButton(Corner.bottomRight),
                ],
              ),
            ),

          // Corner highlight (in auto mode)
          if (_isInitialized && _isDetectionEnabled && _lastDetectedCorner != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: CornerHighlightPainter(_lastDetectedCorner!),
                ),
              ),
            ),

          // Message overlay
          if (_message != null)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _message!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Stats overlay
          if (_isInitialized)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Corner Times',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _isDetectionEnabled ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isDetectionEnabled ? 'AUTO' : 'MANUAL',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTimeDisplay('TL', _timeTracker.cornerTimes[Corner.topLeft.value] ?? 0),
                        _buildTimeDisplay('TR', _timeTracker.cornerTimes[Corner.topRight.value] ?? 0),
                        _buildTimeDisplay('BL', _timeTracker.cornerTimes[Corner.bottomLeft.value] ?? 0),
                        _buildTimeDisplay('BR', _timeTracker.cornerTimes[Corner.bottomRight.value] ?? 0),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCornerButton(Corner corner) {
    final isActive = _timeTracker.currentCorner == corner;

    return GestureDetector(
      onTap: () => _onCornerTapped(corner),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(
            color: isActive ? Colors.green : Colors.white.withValues(alpha: 0.3),
            width: isActive ? 4 : 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            _getCornerName(corner),
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              shadows: const [
                Shadow(
                  color: Colors.black,
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDisplay(String label, int seconds) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        Text(
          '${seconds}s',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Custom painter to highlight the corner with motion
class CornerHighlightPainter extends CustomPainter {
  final Corner corner;

  CornerHighlightPainter(this.corner);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    Rect rect;
    final halfWidth = size.width / 2;
    final halfHeight = size.height / 2;

    switch (corner) {
      case Corner.topLeft:
        rect = Rect.fromLTWH(0, 0, halfWidth, halfHeight);
        break;
      case Corner.topRight:
        rect = Rect.fromLTWH(halfWidth, 0, halfWidth, halfHeight);
        break;
      case Corner.bottomLeft:
        rect = Rect.fromLTWH(0, halfHeight, halfWidth, halfHeight);
        break;
      case Corner.bottomRight:
        rect = Rect.fromLTWH(halfWidth, halfHeight, halfWidth, halfHeight);
        break;
    }

    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(CornerHighlightPainter oldDelegate) {
    return oldDelegate.corner != corner;
  }
}
