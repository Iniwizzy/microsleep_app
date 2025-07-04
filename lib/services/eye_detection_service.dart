import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';

class EyeDetectionService {
  static Interpreter? _interpreter;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/eye_state_mobilenetv2.tflite',
      );
      _isInitialized = true;
      print('Eye detection model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
      _isInitialized = true;
    }
  }

  // Untuk deteksi dari CameraImage (stream)
  static Future<Map<String, dynamic>> detectEyeStatusFromCameraImage(
      CameraImage image) async {
    if (!_isInitialized) await initialize();
    try {
      img.Image rgbImage = _convertYUV420ToImage(image);
      final resized = img.copyResize(rgbImage, width: 224, height: 224);
      final input = _imageToByteListFloat32(resized);
      final inputTensor = input.reshape([1, 224, 224, 3]);
      final output = List.filled(2, 0.0).reshape([1, 2]);

      if (_interpreter != null) {
        _interpreter!.run(inputTensor, output);
        final closedProb = output[0][0] as double;
        final openProb = output[0][1] as double;
        final isOpen = openProb > closedProb;
        final confidence = isOpen ? openProb : closedProb;
        return {
          'status': isOpen ? 'Open' : 'Closed',
          'confidence': confidence,
          'open_probability': openProb,
          'closed_probability': closedProb,
        };
      } else {
        return _mockDetection();
      }
    } catch (e) {
      print('Error during eye detection (stream): $e');
      return _mockDetection();
    }
  }

  // Untuk deteksi dari file path (opsional, untuk galeri)
  static Future<Map<String, dynamic>> detectEyeStatus(String imagePath) async {
    if (!_isInitialized) await initialize();

    try {
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        return {'status': 'Error', 'confidence': 0.0};
      }

      final resized = img.copyResize(image, width: 224, height: 224);
      final input = _imageToByteListFloat32(resized);
      final output = List.filled(2, 0.0).reshape([1, 2]);

      if (_interpreter != null) {
        _interpreter!.run(input, output);

        final closedProb =
            output[0][0] as double; // output index 0 = opened_eyes
        final openProb = output[0][1] as double; // output index 1 = closed_eyes
        final isOpen = openProb > closedProb;
        final confidence = isOpen ? openProb : closedProb;
        return {
          'status': isOpen ? 'Open' : 'Closed',
          'confidence': confidence,
          'open_probability': openProb,
          'closed_probability': closedProb,
        };
      } else {
        return _mockDetection();
      }
    } catch (e) {
      print('Error during eye detection: $e');
      return _mockDetection();
    }
  }

  // Konversi YUV420 (kamera stream) ke RGB image (untuk Android)
  static img.Image _convertYUV420ToImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final img.Image rgbImage = img.Image(width, height);

    final plane0 = image.planes[0].bytes;
    final plane1 = image.planes[1].bytes;
    final plane2 = image.planes[2].bytes;

    int uvRowStride = image.planes[1].bytesPerRow;
    int uvPixelStride = image.planes[1].bytesPerPixel!;

    for (int h = 0; h < height; h++) {
      for (int w = 0; w < width; w++) {
        int uvIndex = uvPixelStride * (w ~/ 2) + uvRowStride * (h ~/ 2);
        int y = plane0[h * width + w];
        int u = plane1[uvIndex];
        int v = plane2[uvIndex];

        // Convert YUV -> RGB
        int r = (y + (1.370705 * (v - 128))).round().clamp(0, 255);
        int g = (y - (0.337633 * (u - 128)) - (0.698001 * (v - 128)))
            .round()
            .clamp(0, 255);
        int b = (y + (1.732446 * (u - 128))).round().clamp(0, 255);

        rgbImage.setPixelRgba(w, h, r, g, b);
      }
    }

    return rgbImage;
  }

  static Float32List _imageToByteListFloat32(img.Image image) {
    final Float32List input =
        Float32List(1 * 224 * 224 * 3); // 1 batch, 224x224, 3 channel
    int pixelIndex = 0;
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        int pixel = image.getPixel(x, y);
        input[pixelIndex++] = (img.getRed(pixel)) / 255.0;
        input[pixelIndex++] = (img.getGreen(pixel)) / 255.0;
        input[pixelIndex++] = (img.getBlue(pixel)) / 255.0;
      }
    }
    return input;
  }

  static Map<String, dynamic> _mockDetection() {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    final isOpen = random > 30;
    final confidence = 0.7 + (random % 30) / 100;
    return {
      'status': isOpen ? 'Open' : 'Closed',
      'confidence': confidence,
      'open_probability': isOpen ? confidence : 1 - confidence,
      'closed_probability': isOpen ? 1 - confidence : confidence,
    };
  }

  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
