import 'package:flutter/material.dart';

/// Mandatory Preliminary Design Disclaimer Banner per SP-AI-10, SP-BR-05, SP-NFR-SAF-01.
class DisclaimerBanner extends StatelessWidget {
  final String? customText;

  const DisclaimerBanner({super.key, this.customText});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRELIMINARY CONCEPTUAL DESIGN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF991B1B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customText ??
                      'This floor plan is an AI-generated conceptual preliminary layout and is not a certified '
                          'architectural or structural engineering drawing. It must be reviewed and stamped by a '
                          'licensed architect or structural engineer prior to construction or municipal submission.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7F1D1D),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
