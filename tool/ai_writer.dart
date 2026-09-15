import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🤖 AI Runtime Writer - กำลังเชื่อมต่อ GitHub...');
  
  final token = Platform.environment['GITHUB_TOKEN'] ?? '';
  if (token.isEmpty) {
    print('กรุณาใส่ token: set GITHUB_TOKEN=ghp_xxx');
    print('แล้วรัน: dart run tool/ai_writer.dart');
    return;
  }

  final owner = 'phakphoum38-stack';
  final repo = 'EqualizerPro';
  final branch = 'pr-3';

  // AI เขียน Runtime แบบ Advanced ให้เลย (มี syntax highlight, mermaid, table, etc)
  final aiGeneratedRuntime = '''
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

/// AI Generated Runtime - Written by AI directly on GitHub
/// Features: Security sanitizer, https only, code highlight, table, link confirm
class EqMarkdownSanitizer {
  static const forbiddenTags = ['script','iframe','form','style','onerror','onclick','onload'];
  static String sanitize(String raw) {
    var t = raw;
    if (t.length > 150000) t = t.substring(0, 150000);
    for (final tag in forbiddenTags) {
      t = t.replaceAll(RegExp('<\[^>]*>.*?</\>', caseSensitive: false, dotAll: true), '');
      t = t.replaceAll(RegExp('<\[^>]*>', caseSensitive: false), '');
    }
    // Block http images, allow only https
    t = t.replaceAllMapped(RegExp(r'!\\[.*?\\]\\((http://.*?)\\)'), (m) => '![](\)');
    return t;
  }
}

class EqMarkdownViewer extends StatelessWidget {
  final String data;
  final bool enableLinkConfirm;
  const EqMarkdownViewer({super.key, required this.data, this.enableLinkConfirm = true});

  @override
  Widget build(BuildContext context) {
    final safe = EqMarkdownSanitizer.sanitize(data);
    return MarkdownBody(
      data: safe,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        h1: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 26, color: Color(0xFFC8FF3D)),
        h2: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 20),
        h3: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        p: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.65, fontSize: 14.5, color: Colors.white.withOpacity(0.9)),
        code: TextStyle(fontFamily: 'monospace', backgroundColor: Color(0xFF1E1E1E), color: Color(0xFFC8FF3D)),
        codeblockDecoration: BoxDecoration(color: Color(0xFF1A1F2A), borderRadius: BorderRadius.circular(10), border: Border.all(color: Color(0xFF2B333F))),
        codeblockPadding: EdgeInsets.all(14),
        blockquoteDecoration: BoxDecoration(color: Color(0xFF111720), border: Border(left: BorderSide(color: Color(0xFFC8FF3D), width: 4))),
        tableBorder: TableBorder.all(color: Color(0xFF2B333F)),
      ),
      onTapLink: (text, href, title) async {
        if (href == null) return;
        if (enableLinkConfirm) {
          final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: Text('เปิดลิงก์?'), content: Text(href), actions: [TextButton(onPressed: ()=>Navigator.pop(c,false), child: Text('ยกเลิก')), FilledButton(onPressed: ()=>Navigator.pop(c,true), child: Text('เปิด'))]));
          if (ok != true) return;
        }
        final uri = Uri.tryParse(href);
        if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      imageBuilder: (uri, title, alt) {
        final url = uri.toString();
        if (!url.startsWith('https://')) return Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(Icons.block, color: Colors.red), SizedBox(width: 8), Expanded(child: Text('Blocked non-https image', style: TextStyle(color: Colors.red)))]));
        return Padding(padding: EdgeInsets.symmetric(vertical: 10), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: url, placeholder: (c,u)=>Container(height: 120, child: Center(child: CircularProgressIndicator())), errorWidget: (c,u,e)=>Icon(Icons.broken_image, color: Colors.grey))));
      },
    );
  }
}

/// AI Bonus: Markdown with Preview Toggle
class EqMarkdownWithPreview extends StatefulWidget {
  final String markdown;
  const EqMarkdownWithPreview({super.key, required this.markdown});
  @override
  State<EqMarkdownWithPreview> createState() => _EqMarkdownWithPreviewState();
}
class _EqMarkdownWithPreviewState extends State<EqMarkdownWithPreview> {
  bool preview = true;
  @override
  Widget build(BuildContext context) {
    return Column(children: [SwitchListTile(title: Text('Preview'), value: preview, onChanged: (v)=>setState(()=>preview=v)), Expanded(child: preview ? SingleChildScrollView(child: EqMarkdownViewer(data: widget.markdown)) : SingleChildScrollView(child: SelectableText(widget.markdown)))]);
  }
}
''';

  // Push ด้วย GitHub API แบบ Flutter http ที่คุณขอ
  Future<bool> pushFile(String path, String content) async {
    final shaUrl = Uri.parse('https://api.github.com/repos/\/\/contents/\=\');
    final shaRes = await http.get(shaUrl, headers: {'Authorization':'Bearer \','Accept':'application/vnd.github.v3+json'});
    String? sha;
    if (shaRes.statusCode == 200) sha = jsonDecode(shaRes.body)['sha'];
    
    final url = Uri.parse('https://api.github.com/repos/\/\/contents/\');
    final body = jsonEncode({
      'message': 'feat: AI writes runtime directly on GitHub via Flutter API',
      'content': base64Encode(utf8.encode(aiGeneratedRuntime)),
      'branch': branch,
      if (sha != null) 'sha': sha
    });
    final res = await http.put(url, headers: {'Authorization':'Bearer \','Accept':'application/vnd.github.v3+json','Content-Type':'application/json'}, body: body);
    return res.statusCode == 200 || res.statusCode == 201;
  }

  print('📤 AI กำลังเขียน lib/core/markdown/markdown_runtime.dart ลง GitHub...');
  final ok = await pushFile('lib/core/markdown/markdown_runtime.dart', aiGeneratedRuntime);
  if (ok) {
    print('✅ AI เขียน Runtime ลง GitHub สำเร็จแล้ว!');
    print('ดูที่ https://github.com/\/\/pull/3/files');
  } else {
    print('❌ Push ไม่สำเร็จ ตรวจสอบ token');
  }
}
