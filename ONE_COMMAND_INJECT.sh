#!/bin/bash
# EqualizerPro - ONE COMMAND INJECTOR
# คำสั่งเดียวจบ - ยิง Flutter Runtime เข้า PR #3
# วิธีใช้: วางคำสั่งนี้ใน Terminal ทีเดียวจบ

set -e

echo "🎵 ONE-COMMAND: ยิง Flutter Runtime เข้า PR #3..."

# ตรวจสอบว่ามีโฟลเดอร์ EqualizerPro หรือยัง
if [ ! -d "EqualizerPro" ]; then
  echo "📥 โคลน repo..."
  git clone https://github.com/phakphoum38-stack/EqualizerPro.git
fi

cd EqualizerPro
git fetch origin pull/3/head:pr-3 || git fetch origin
git checkout pr-3 || git checkout -b pr-3 origin/pr-3 || git checkout main

echo "📦 ยิง dependencies..."
flutter pub add flutter_markdown:^0.7.4+1 cached_network_image:^3.3.1 url_launcher:^6.2.5 > /dev/null 2>&1 || true

echo "📁 สร้างโฟลเดอร์..."
mkdir -p lib/core/markdown
mkdir -p lib/features/help/presentation/pages
mkdir -p lib/features/presets/presentation/widgets
mkdir -p lib/features/equalizer/presentation/widgets
mkdir -p lib/features/ai/presentation/pages
mkdir -p tool

echo "📝 ยิง runtime file..."

cat > lib/core/markdown/markdown_runtime.dart << 'DART_EOF'
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class EqMarkdownConfig {
  static const int maxInputLength = 102400;
  static const double imageMaxHeight = 400;
}

class EqMarkdownSanitizer {
  static const forbidden = ['script', 'iframe', 'form', 'style', 'onerror', 'onclick'];
  static String sanitize(String raw) {
    var text = raw.trim();
    if (text.length > EqMarkdownConfig.maxInputLength) {
      text = text.substring(0, EqMarkdownConfig.maxInputLength);
    }
    for (final tag in forbidden) {
      text = text.replaceAll(RegExp('<$tag[^>]*>.*?</$tag>', caseSensitive: false, dotAll: true), '');
      text = text.replaceAll(RegExp('<$tag[^>]*>', caseSensitive: false), '');
    }
    text = text.replaceAllMapped(RegExp(r'!\[.*?\]\((http://.*?)\)'), (m) => m.group(0)!.replaceAll('http://', 'https://'));
    return text;
  }
}

class EqMarkdownViewer extends StatelessWidget {
  final String data;
  final bool enableLinkConfirm;
  const EqMarkdownViewer({super.key, required this.data, this.enableLinkConfirm = true});
  @override
  Widget build(BuildContext context) {
    final safeData = EqMarkdownSanitizer.sanitize(data);
    return RepaintBoundary(
      child: MarkdownBody(
        data: safeData,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          h1: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 26),
          h2: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 20),
          h3: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
          p: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6, fontSize: 14),
          code: TextStyle(fontFamily: 'monospace', fontSize: 12, backgroundColor: Theme.of(context).colorScheme.surfaceVariant),
          codeblockDecoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(8)),
          codeblockPadding: const EdgeInsets.all(12),
          blockquoteDecoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.08), border: Border(left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 4))),
          blockquotePadding: const EdgeInsets.all(12),
          tableBorder: TableBorder.all(color: Theme.of(context).dividerColor),
        ),
        onTapLink: (text, href, title) async {
          if (href == null) return;
          if (enableLinkConfirm) {
            final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('เปิดลิงก์ภายนอก?'), content: Text(href, style: const TextStyle(fontSize: 12)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('เปิด'))]));
            if (ok != true) return;
          }
          final uri = Uri.tryParse(href);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        imageBuilder: (uri, title, alt) {
          final url = uri.toString();
          if (!url.startsWith('https://')) return Container(padding: const EdgeInsets.all(8), color: Colors.red.shade50, child: Row(children: [const Icon(Icons.block, size: 16), const SizedBox(width: 6), Expanded(child: Text('Blocked: $alt', style: const TextStyle(fontSize: 12)))]));
          return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: url, placeholder: (c, u) => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())), errorWidget: (c, u, e) => const Icon(Icons.broken_image), memCacheHeight: 400)));
        },
      ),
    );
  }
}

class EqPresetMarkdownCard extends StatelessWidget {
  final String title;
  final String markdownDescription;
  const EqPresetMarkdownCard({super.key, required this.title, required this.markdownDescription});
  @override
  Widget build(BuildContext context) {
    return Card(margin: const EdgeInsets.all(8), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleLarge), const Divider(), EqMarkdownViewer(data: markdownDescription)])));
  }
}
DART_EOF

cat > lib/features/help/presentation/pages/help_page.dart << 'DART_EOF'
import 'package:flutter/material.dart';
import '../../../../core/markdown/markdown_runtime.dart';
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});
  static const String helpMarkdown = """
# EqualizerPro v1.2.0+3

Responsive Flutter audio workspace สำหรับ Web, Mobile, Desktop

## 🎵 สิ่งที่ทำได้
- ลากไฟล์ MP3, WAV, OGG, FLAC
- เล่น, หยุด, เลื่อน, ข้าม, สุ่ม, วนซ้ำ
- 10-band parametric EQ แบบ real-time
- 6 preset + save custom profile

## 🎛️ DSP Effects
| Effect | หน้าที่ | แนะนำ |
| --- | --- | --- |
| Bass Boost | เพิ่มเบส 60Hz | +3 ถึง +6dB |
| Reverb | เพิ่มมิติ | 0.2-0.4 |
| Stereo Width | ขยายสเตอริโอ | 1.2-1.5 |
| Limiter | ป้องกันแตก | เปิดไว้เสมอ |

> **WARNING:** อย่าเปิด gain เกิน +12dB

## ▶️ YouTube
1. เปิดแท็บ YouTube > Open YouTube / Google login
2. ล็อกอินใน browser ที่ปลอดภัย
3. Copy URL > Paste link ในแอป

## 📦 Code ตัวอย่าง
```json
{
  "name": "Bass Boost",
  "bands": [{"freq": 60, "gain": 6.0, "q": 1.2}]
}
```
""";
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Help & Guide')), body: const SingleChildScrollView(padding: EdgeInsets.all(16), child: EqMarkdownViewer(data: helpMarkdown)));
  }
}
DART_EOF

cat > lib/features/ai/presentation/pages/ai_assistant_tab.dart << 'DART_EOF'
import 'package:flutter/material.dart';
import '../../../../core/markdown/markdown_runtime.dart';
class AiAssistantTab extends StatefulWidget { const AiAssistantTab({super.key}); @override State<AiAssistantTab> createState() => _AiAssistantTabState(); }
class _AiAssistantTabState extends State<AiAssistantTab> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [{'role': 'assistant', 'content': "# EQ Assistant 🎧\n\nบอกแนวเพลงที่ฟังมาเลยครับ\n\nเช่น `EDM`, `Podcast`, `Gaming`\n\n## Preset ที่มี\n- **Bass Boost** - EDM, Hip-Hop\n- **Vocal** - Podcast\n- **Flat** - อ้างอิง"}];
  bool _thinking = false;
  void _send() {
    final t = _controller.text.trim(); if (t.isEmpty) return;
    setState(() { _messages.add({'role': 'user', 'content': t}); _thinking = true; });
    _controller.clear();
    Future.delayed(const Duration(seconds: 1), () {
      String res;
      if (t.toLowerCase().contains('edm') || t.contains('เบส')) { res = "## แนะนำ: Bass Boost\n\n- **60Hz +6dB** เบสหนัก\n- **230Hz -1.5dB** ลดอู้\n- **12kHz +2dB** เพิ่มใส\n\n> **INFO:** เหมาะกับหูฟังเบสหนัก"; }
      else if (t.toLowerCase().contains('podcast')) { res = "## แนะนำ: Vocal\n\n- **250Hz -3dB** ลดอู้\n- **2kHz +3.5dB** เพิ่มชัด\n\nเหมาะสำหรับ Podcast"; }
      else { res = "## ลอง Preset นี้\n\n```json\n{\"freq\": 60, \"gain\": 2}\n```\n\nบอกแนวเพลงเพิ่มได้เลยครับ"; }
      setState(() { _messages.add({'role': 'assistant', 'content': res}); _thinking = false; });
    });
  }
  @override
  Widget build(BuildContext context) {
    return Column(children: [Expanded(child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: _messages.length + (_thinking ? 1 : 0), itemBuilder: (c, i) { if (_thinking && i == _messages.length) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Row(children: [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 12), Text('กำลังคิด...')]))); final m = _messages[i]; final isUser = m['role'] == 'user'; return Align(alignment: isUser ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical: 4), constraints: BoxConstraints(maxWidth: MediaQuery.of(c).size.width * 0.85), child: Card(color: isUser ? Theme.of(c).colorScheme.primaryContainer : null, child: Padding(padding: const EdgeInsets.all(12), child: isUser ? Text(m['content']!) : EqMarkdownViewer(data: m['content']!))))); })), const Divider(height: 1), Padding(padding: const EdgeInsets.all(8), child: Row(children: [Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'พิมพ์แนวเพลง...', border: OutlineInputBorder(), isDense: true), onSubmitted: (_) => _send())), const SizedBox(width: 8), IconButton.filled(onPressed: _send, icon: const Icon(Icons.send))]))]);
  }
}
DART_EOF

echo "✅ ยิงไฟล์เสร็จ"

echo "🔧 flutter pub get..."
flutter pub get > /dev/null 2>&1 && echo "✅ pub get สำเร็จ" || echo "⚠️ รัน flutter pub get เองอีกที"

echo ""
echo "🧪 flutter analyze..."
flutter analyze --no-pub | head -20

echo ""
echo "🎉 ยิง Flutter Runtime เข้า PR #3 เสร็จแล้ว!"
echo "=================================================="
echo "ทดสอบ: flutter run -d chrome"
echo "Push: git add . && git commit -m 'feat: inject markdown runtime V3' && git push origin pr-3"
echo ""
echo "ใช้งาน:"
echo "  import 'core/markdown/markdown_runtime.dart';"
echo "  EqMarkdownViewer(data: markdown)"
