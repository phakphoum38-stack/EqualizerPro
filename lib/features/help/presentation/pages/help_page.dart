import 'package:flutter/material.dart';
import '../../../../core/markdown/markdown_runtime.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const helpMd = '''
# 🎵 EqualizerPro Help

## EQ Basics
- **Low (60Hz)**: Bass, kick drum
- **Low-Mid (250Hz)**: Warmth
- **Mid (1kHz)**: Vocal presence
- **High-Mid (4kHz)**: Clarity
- **High (12kHz)**: Air, brightness

## Security
Markdown rendered with \EqMarkdownSanitizer\ - auto blocks:
- \<script>\, \<iframe>\, \<form>\
- \http://\ images (only https:// allowed)

## Example
\\\dart
EqMarkdownViewer(data: "# Hello EqualizerPro")
\\\

> Built with Flutter + flutter_markdown + security sanitizer
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B11),
      appBar: AppBar(
        title: const Text('Help'),
        backgroundColor: const Color(0xFF111720),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: EqMarkdownViewer(data: helpMd),
      ),
    );
  }
}
