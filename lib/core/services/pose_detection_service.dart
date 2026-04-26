import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseDetectionService {
  final _detector = PoseDetector(
    options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
  );
  bool _isBusy = false;

  /// Converts [image] to InputImage and runs pose detection.
  /// Returns null if busy or conversion fails.
  Future<List<Pose>?> processFrame(
    CameraImage image,
    CameraDescription camera,
  ) async {
    if (_isBusy) return null;
    _isBusy = true;
    try {
      final inputImage = _toInputImage(image, camera);
      if (inputImage == null) return null;
      return await _detector.processImage(inputImage);
    } catch (e) {
      debugPrint('PoseDetectionService error: $e');
      return null;
    } finally {
      _isBusy = false;
    }
  }

  InputImage? _toInputImage(CameraImage image, CameraDescription camera) {
    // iOS BGRA8888 stream delivers images already in portrait orientation
    // (height > width), so no rotation is needed — passing rotation90deg
    // would double-rotate the coordinates.
    final rotation = (Platform.isIOS && image.height > image.width)
        ? InputImageRotation.rotation0deg
        : _inputRotation(camera.sensorOrientation);

    if (Platform.isIOS) {
      final plane = image.planes[0];
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    }

    // Android: concatenate YUV planes
    if (Platform.isAndroid) {
      final bytes = _concatenatePlanes(image.planes);
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.yuv_420_888,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    }

    return null;
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final buffer = WriteBuffer();
    for (final plane in planes) {
      buffer.putUint8List(plane.bytes);
    }
    return buffer.done().buffer.asUint8List();
  }

  InputImageRotation _inputRotation(int sensorOrientation) =>
      switch (sensorOrientation) {
        90 => InputImageRotation.rotation90deg,
        180 => InputImageRotation.rotation180deg,
        270 => InputImageRotation.rotation270deg,
        _ => InputImageRotation.rotation0deg,
      };

  void dispose() => _detector.close();
}
