import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  CameraDescription? _currentCamera;

  CameraController? get controller => _controller;
  CameraDescription? get currentCamera => _currentCamera;
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  /// Initialize camera service and request permissions
  Future<bool> initialize() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      return false;
    }

    // Get available cameras
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        return false;
      }

      // Use the first available camera (usually back camera)
      await _initializeCamera(_cameras!.first);
      return true;
    } catch (e) {
      print('Error initializing camera: $e');
      return false;
    }
  }

  /// Initialize camera controller with specific camera
  Future<void> _initializeCamera(CameraDescription camera) async {
    _currentCamera = camera;
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();
  }

  /// Switch between front and back camera
  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      return;
    }

    final currentCamera = _controller?.description;
    final newCamera = _cameras!.firstWhere(
      (camera) => camera.lensDirection != currentCamera?.lensDirection,
      orElse: () => _cameras!.first,
    );

    await dispose();
    await _initializeCamera(newCamera);
  }

  /// Take a picture and return the file path
  Future<XFile?> takePicture() async {
    if (!isInitialized) {
      return null;
    }

    try {
      final image = await _controller!.takePicture();
      return image;
    } catch (e) {
      print('Error taking picture: $e');
      return null;
    }
  }

  /// Dispose camera controller
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
