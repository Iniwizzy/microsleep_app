import 'package:flutter/material.dart';

class CameraControls extends StatelessWidget {
  final VoidCallback onCapture;
  final VoidCallback onPickImage;
  final VoidCallback onClose;
  final bool isProcessing;

  const CameraControls({
    super.key,
    required this.onCapture,
    required this.onPickImage,
    required this.onClose,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    double containerHeight = MediaQuery.of(context).size.height * 0.2;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: containerHeight,
        decoration: const BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: isProcessing ? null : onCapture,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 50),
                child: GestureDetector(
                  onTap: onClose,
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.close, color: Colors.orange),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 50),
                child: GestureDetector(
                  onTap: isProcessing ? null : onPickImage,
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: const Icon(
                      Icons.photo_library,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
