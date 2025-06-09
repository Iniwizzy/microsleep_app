import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:appcamera/providers/eye_detection_provider.dart';
import 'package:appcamera/services/eye_detection_service.dart';
import 'dart:async';

class EyeDetectionCamera extends StatefulWidget {
  final List<CameraDescription> cameras;

  const EyeDetectionCamera({super.key, required this.cameras});

  @override
  State<EyeDetectionCamera> createState() => _EyeDetectionCameraState();
}

class _EyeDetectionCameraState extends State<EyeDetectionCamera> {
  late CameraController _controller;
  Timer? _detectionTimer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _startContinuousDetection();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      widget.cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => widget.cameras.first,
      ),
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller.initialize();
    if (mounted) {
      setState(() {});
      Provider.of<EyeDetectionProvider>(context, listen: false)
          .setDetecting(true);
    }
  }

  void _startContinuousDetection() {
    _detectionTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isProcessing && _controller.value.isInitialized) {
        _captureAndDetect();
      }
    });
  }

  Future<void> _captureAndDetect() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final image = await _controller.takePicture();
      final result = await EyeDetectionService.detectEyeStatus(image.path);

      if (mounted) {
        Provider.of<EyeDetectionProvider>(context, listen: false)
            .updateEyeStatus(result['status'], result['confidence']);
      }
    } catch (e) {
      print('Detection error: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _controller.dispose();
    Provider.of<EyeDetectionProvider>(context, listen: false)
        .setDetecting(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Initializing Camera...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<EyeDetectionProvider>(
        builder: (context, provider, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Camera Preview
              CameraPreview(_controller),

              // Detection Overlay
              _buildDetectionOverlay(provider),

              // Top Status Bar
              _buildTopStatusBar(provider),

              // Bottom Controls
              _buildBottomControls(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetectionOverlay(EyeDetectionProvider provider) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: EyeDetectionOverlayPainter(
        eyeStatus: provider.eyeStatus,
        confidence: provider.confidence,
        isProcessing: _isProcessing,
      ),
    );
  }

  Widget _buildTopStatusBar(EyeDetectionProvider provider) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;

    switch (provider.eyeStatus.toLowerCase()) {
      case 'open':
        statusColor = Colors.green;
        statusIcon = Icons.visibility;
        break;
      case 'closed':
        statusColor = Colors.red;
        statusIcon = Icons.visibility_off;
        break;
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(statusIcon, color: statusColor, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Eyes: ${provider.eyeStatus}',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Confidence: ${(provider.confidence * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCounterItem('Open', provider.openCount, Colors.green),
                Container(width: 1, height: 20, color: Colors.white30),
                _buildCounterItem('Closed', provider.closedCount, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            heroTag: "reset",
            onPressed: () {
              Provider.of<EyeDetectionProvider>(context, listen: false)
                  .resetCounters();
            },
            backgroundColor: Colors.orange,
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
          FloatingActionButton(
            heroTag: "close",
            onPressed: () => Navigator.pop(context),
            backgroundColor: Colors.white,
            child: const Icon(Icons.close, color: Colors.black),
          ),
        ],
      ),
    );
  }
}

class EyeDetectionOverlayPainter extends CustomPainter {
  final String eyeStatus;
  final double confidence;
  final bool isProcessing;

  EyeDetectionOverlayPainter({
    required this.eyeStatus,
    required this.confidence,
    required this.isProcessing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw eye detection area
    final centerX = size.width / 2;
    final centerY = size.height / 2 - 50;
    final eyeAreaWidth = size.width * 0.7;
    final eyeAreaHeight = size.height * 0.4;

    final eyeRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: eyeAreaWidth,
      height: eyeAreaHeight,
    );

    // Set color based on eye status
    Color rectColor;
    switch (eyeStatus.toLowerCase()) {
      case 'open':
        rectColor = Colors.green;
        break;
      case 'closed':
        rectColor = Colors.red;
        break;
      default:
        rectColor = Colors.grey;
    }

    // Add processing animation
    if (isProcessing) {
      paint.color = rectColor.withOpacity(0.5);
    } else {
      paint.color = rectColor;
    }

    // Draw detection rectangle
    canvas.drawRRect(
      RRect.fromRectAndRadius(eyeRect, const Radius.circular(16)),
      paint,
    );

    // Draw corner indicators
    final cornerLength = 25.0;
    final corners = [
      // Top-left
      [
        Offset(eyeRect.left, eyeRect.top + cornerLength),
        Offset(eyeRect.left, eyeRect.top),
        Offset(eyeRect.left + cornerLength, eyeRect.top)
      ],
      // Top-right
      [
        Offset(eyeRect.right - cornerLength, eyeRect.top),
        Offset(eyeRect.right, eyeRect.top),
        Offset(eyeRect.right, eyeRect.top + cornerLength)
      ],
      // Bottom-left
      [
        Offset(eyeRect.left, eyeRect.bottom - cornerLength),
        Offset(eyeRect.left, eyeRect.bottom),
        Offset(eyeRect.left + cornerLength, eyeRect.bottom)
      ],
      // Bottom-right
      [
        Offset(eyeRect.right - cornerLength, eyeRect.bottom),
        Offset(eyeRect.right, eyeRect.bottom),
        Offset(eyeRect.right, eyeRect.bottom - cornerLength)
      ],
    ];

    paint.strokeWidth = 4;
    for (final corner in corners) {
      final path = Path()
        ..moveTo(corner[0].dx, corner[0].dy)
        ..lineTo(corner[1].dx, corner[1].dy)
        ..lineTo(corner[2].dx, corner[2].dy);
      canvas.drawPath(path, paint);
    }

    // Draw center crosshair
    paint.strokeWidth = 2;
    paint.color = rectColor.withOpacity(0.7);

    // Horizontal line
    canvas.drawLine(
      Offset(centerX - 20, centerY),
      Offset(centerX + 20, centerY),
      paint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(centerX, centerY - 20),
      Offset(centerX, centerY + 20),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
