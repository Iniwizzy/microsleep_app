import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class EyeDetectionService {
  static Interpreter? _interpreter;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load the TFLite model
      _interpreter = await Interpreter.fromAsset(
        'assets/models/eye_detection_model.tflite',
      );
      _isInitialized = true;
      print('Eye detection model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
      // Fallback - create a mock model for demonstration
      _isInitialized = true;
    }
  }

  static Future<Map<String, dynamic>> detectEyeStatus(String imagePath) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Read and preprocess image
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        return {'status': 'Error', 'confidence': 0.0};
      }

      // Resize image to model input size (typically 224x224 for eye detection)
      final resized = img.copyResize(image, width: 224, height: 224);

      // Convert to input tensor
      final input = _imageToByteListFloat32(resized);
      final output = List.filled(2, 0.0).reshape([1, 2]); // [closed, open]

      // Run inference
      if (_interpreter != null) {
        _interpreter!.run(input, output);

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
        // Mock detection for demonstration
        return _mockDetection();
      }
    } catch (e) {
      print('Error during eye detection: $e');
      return _mockDetection();
    }
  }

  static Float32List _imageToByteListFloat32(img.Image image) {
    var convertedBytes = Float32List(1 * 224 * 224 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (int i = 0; i < 224; i++) {
      for (int j = 0; j < 224; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (img.getRed(pixel) - 127.5) / 127.5;
        buffer[pixelIndex++] = (img.getGreen(pixel) - 127.5) / 127.5;
        buffer[pixelIndex++] = (img.getBlue(pixel) - 127.5) / 127.5;
      }
    }

    // Tidak pakai reshape!
    return convertedBytes;
  }

  static Map<String, dynamic> _mockDetection() {
    // Mock detection for demonstration purposes
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    final isOpen = random > 30; // 70% chance of open eyes
    final confidence = 0.7 + (random % 30) / 100; // 0.7 to 0.99

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
