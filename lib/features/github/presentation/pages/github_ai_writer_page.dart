import 'package:flutter/material.dart';
import '../../../../core/github/github_api_service.dart';
import '../../../../core/markdown/markdown_runtime.dart';

class GithubAiWriterPage extends StatefulWidget {
  const GithubAiWriterPage({super.key});
  @override
  State<GithubAiWriterPage> createState() => _GithubAiWriterPageState();
}

class _GithubAiWriterPageState extends State<GithubAiWriterPage> {
  final tokenCtrl = TextEditingController();
  final branchCtrl = TextEditingController(text: 'pr-3');
  bool isWriting = false;
  String log = 'พร้อมเขียนงานค้างบน GitHub...';
  String selectedTask = 'สร้างไฟล์ที่ค้างทั้งหมด';

  final pendingTasks = {
    'สร้างไฟล์ที่ค้างทั้งหมด': {
      'lib/features/presets/presentation/widgets/preset_doc_sheet.dart': '''
import 'package:flutter/material.dart';
import '../../../../core/markdown/markdown_runtime.dart';
class PresetDocSheet extends StatelessWidget {
  final String doc;
  const PresetDocSheet({super.key, required this.doc});
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (c, sc) => Container(
        decoration: BoxDecoration(color: Color(0xFF111720), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SingleChildScrollView(controller: sc, padding: EdgeInsets.all(20), child: EqMarkdownViewer(data: doc)),
      ),
    );
  }
}
''',
      'lib/features/help/presentation/pages/help_page.dart': '''
import 'package:flutter/material.dart';
import '../../../../core/markdown/markdown_runtime.dart';
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF080B11),
      appBar: AppBar(title: Text('Help')),
      body: SingleChildScrollView(padding: EdgeInsets.all(16), child: EqMarkdownViewer(data: "# Help\\n\\n- Bass 60Hz\\n- Mid 1kHz\\n- High 12kHz")),
    );
  }
}
''',
    },
  };

  Future<void> writePendingWork() async {
    if (tokenCtrl.text.isEmpty) {
      setState(() => log = '❌ ใส่ GitHub Token ก่อน (สร้างที่ github.com/settings/tokens)');
      return;
    }
    setState(() {
      isWriting = true;
      log = '🤖 AI กำลังเขียนงานค้างบน GitHub...\nBranch: ${branchCtrl.text}\n';
    });

    final api = GitHubApiService(token: tokenCtrl.text);
    final files = pendingTasks[selectedTask]!;

    try {
      log += '📤 กำลัง push ${files.length} ไฟล์...\n';
      final ok = await api.pushMultipleFiles(
        files: files,
        branch: branchCtrl.text,
        message: 'feat: AI writes pending work via Flutter API - $selectedTask',
      );
      setState(() {
        log += ok? '✅ เขียนงานค้างเสร็จแล้วบน GitHub!\nดูที่ https://github.com/phakphoum38-stack/EqualizerPro/pull/3/files' : '❌ Push ไม่สำเร็จ ตรวจสอบ Token/Branch';
        isWriting = false;
      });
    } catch (e) {
      setState(() {
        log += '❌ Error: $e';
        isWriting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B11),
      appBar: AppBar(
        title: const Text('AI Writer - เขียนงานค้างบน GitHub'),
        backgroundColor: const Color(0xFF111720),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: tokenCtrl,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'GitHub Token (ghp_...)',
              hintText: 'สร้างที่ github.com/settings/tokens/new',
              filled: true,
              fillColor: const Color(0xFF111720),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: branchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Branch',
                    filled: true,
                    fillColor: const Color(0xFF111720),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: selectedTask,
                dropdownColor: const Color(0xFF111720),
                style: const TextStyle(color: Colors.white),
                items: pendingTasks.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                onChanged: (v) => setState(() => selectedTask = v!),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC8FF3D),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.all(16),
            ),
            onPressed: isWriting? null : writePendingWork,
            icon: isWriting? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
            label: Text(isWriting? 'AI กำลังเขียน...' : 'ให้ AI เขียนงานค้างบน GitHub เลย'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF111720),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2B333F)),
            ),
            child: EqMarkdownViewer(data: "```\n$log\n```"),
          ),
          const SizedBox(height: 20),
          const EqMarkdownViewer(data: '''
## วิธีใช้
1. สร้าง Token ที่ `github.com/settings/tokens/new` ติ๊ก `repo`
2. วาง Token ด้านบน
3. กดปุ่ม **ให้ AI เขียนงานค้างบน GitHub เลย**
4. AI จะใช้ `GitHubApiService.pushMultipleFiles()` เขียนไฟล์ที่ค้างลง `pr-3` ให้เลย

> ใช้ Flutter API ที่มีแล้ว ไม่ต้องไปทำบนเครื่อง
'''),
        ],
      ),
    );
  }
}
