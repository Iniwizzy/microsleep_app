import 'package:flutter/foundation.dart';

class EyeDetectionProvider extends ChangeNotifier {
  String _eyeStatus = 'Unknown';
  bool _isDetecting = false;
  double _confidence = 0.0;
  int _openCount = 0;
  int _closedCount = 0;
  DateTime? _lastDetectionTime;

  // Getters
  String get eyeStatus => _eyeStatus;
  bool get isDetecting => _isDetecting;
  double get confidence => _confidence;
  int get openCount => _openCount;
  int get closedCount => _closedCount;
  DateTime? get lastDetectionTime => _lastDetectionTime;

  // Eye detection methods
  void updateEyeStatus(String status, double confidence) {
    _eyeStatus = status;
    _confidence = confidence;
    _lastDetectionTime = DateTime.now();

    // Update counters
    if (status.toLowerCase() == 'open') {
      _openCount++;
    } else if (status.toLowerCase() == 'closed') {
      _closedCount++;
    }

    notifyListeners();
  }

  void setDetecting(bool detecting) {
    _isDetecting = detecting;
    notifyListeners();
  }

  void resetCounters() {
    _openCount = 0;
    _closedCount = 0;
    notifyListeners();
  }

  void resetDetection() {
    _eyeStatus = 'Unknown';
    _confidence = 0.0;
    _isDetecting = false;
    _lastDetectionTime = null;
    notifyListeners();
  }
}
