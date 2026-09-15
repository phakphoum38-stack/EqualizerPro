import 'package:flutter/material.dart';
import '../../../../core/markdown/markdown_runtime.dart';
import '../../../equalizer/presentation/widgets/eq_markdown_with_preview.dart';

class AiAssistantTab extends StatefulWidget {
  const AiAssistantTab({super.key});
  @override
  State<AiAssistantTab> createState() => _AiAssistantTabState();
}

class _AiAssistantTabState extends State<AiAssistantTab> {
  final _controller = TextEditingController();
  String response = "สวัสดีครับ! 👋 ถามเรื่อง EQ ได้เลย เช่น 'ทำยังไงให้เบสแน่น'";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: EqMarkdownWithPreview(markdown: response),
          ),
        ),
        Container(
          padding: EdgeInsets.all(12),
          color: Color(0xFF111720),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'ถาม AI เรื่อง EQ...',
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Color(0xFF1A1F2A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Color(0xFFC8FF3D), foregroundColor: Colors.black),
                onPressed: () {
                  setState(() {
                    response = '''
# คำตอบสำหรับ: \

## 💡 EQ Tip
- **เบสแน่น**: Boost 60-80Hz เล็กน้อย, Cut 200-300Hz ถ้าบวม
- **เสียงร้องชัด**: Boost 2-4kHz
- **ใส โปร่ง**: Boost 10-12kHz แบบ shelf

\\\
Low: +2dB @ 60Hz
Mid: +1dB @ 1kHz  
High: +1.5dB @ 12kHz
\\\

> Rendered with \EqMarkdownViewer\ + Security Sanitizer
''';
                  });
                },
                child: Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
