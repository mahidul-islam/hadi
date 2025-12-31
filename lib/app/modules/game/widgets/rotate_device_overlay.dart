import 'package:flutter/material.dart';

class RotateDeviceOverlay extends StatelessWidget {
  final VoidCallback onCheckAgain;

  const RotateDeviceOverlay({super.key, required this.onCheckAgain});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rotate icon
            const Icon(Icons.screen_rotation, size: 80, color: Colors.white),
            const SizedBox(height: 24),
            // Message in Bangla
            const Text(
              'অনুগ্রহ করে আপনার ডিভাইস ঘোরান',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'গেম খেলার জন্য ল্যান্ডস্কেপ মোড প্রয়োজন',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Check again button in Bangla
            ElevatedButton(
              onPressed: onCheckAgain,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'আবার পরীক্ষা করুন',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
