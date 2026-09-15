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
  bool isLoadingPRs = false;
  String log = 'พร้อมเขียนงานค้างบน GitHub...';
  String selectedTask = 'สร้างไฟล์ที่ค้างทั้งหมด';
  List<Map<String, dynamic>> prs = [];
  Map<String, dynamic>? selectedPR;

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
      body: SingleChildScrollView(padding: EdgeInsets.all(16), child: EqMarkdownViewer(data: "# Help")),
    );
  }
}
''',
    },
  };

  Future<void> loadPRs() async {
    if (tokenCtrl.text.isEmpty) {
      setState(() => log = '❌ ใส่ Token ก่อนเพื่อโหลด PR');
      return;
    }
    setState(() => isLoadingPRs = true);
    final api = GitHubApiService(token: tokenCtrl.text);
    final list = await api.listPullRequests();
    setState(() {
      prs = list;
      isLoadingPRs = false;
      if (prs.isNotEmpty) {
        selectedPR = prs.firstWhere((p) => p['branch'] == 'pr-3', orElse: () => prs.first);
        branchCtrl.text = selectedPR!['branch'];
        log = '✅ โหลด PR ได้ ${prs.length} ตัว\nเลือก PR แล้วจะ auto ใส่ branch ให้';
      } else {
        log = '❌ ไม่พบ PR หรือ Token ไม่มีสิทธิ์';
      }
    });
  }

  Future<void> writePendingWork() async {
    if (tokenCtrl.text.isEmpty) {
      setState(() => log = '❌ ใส่ GitHub Token ก่อน');
      return;
    }
    setState(() {
      isWriting = true;
      log = '🤖 AI กำลังเขียนงานค้าง...\nPR: #${selectedPR?['number'] ?? '-'} ${selectedPR?['title'] ?? ''}\nBranch: ${branchCtrl.text}\n';
    });

    final api = GitHubApiService(token: tokenCtrl.text);
    final files = pendingTasks[selectedTask]!;

    try {
      final ok = await api.pushMultipleFiles(
        files: files,
        branch: branchCtrl.text,
        message: 'feat: AI writes pending work to PR #${selectedPR?['number']} via Flutter API',
      );
      setState(() {
        log += ok? '✅ เขียนลง PR #${selectedPR?['number']} สำเร็จ!\nhttps://github.com/phakphoum38-stack/EqualizerPro/pull/${selectedPR?['number']}/files' : '❌ Push ไม่สำเร็จ';
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
      appBar: AppBar(title: const Text('AI Writer - เลือก PR ได้'), backgroundColor: const Color(0xFF111720)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: tokenCtrl,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'GitHub Token (ghp_...)',
              suffixIcon: IconButton(icon: Icon(Icons.download), onPressed: loadPRs),
              filled: true,
              fillColor: const Color(0xFF111720),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (_) => loadPRs(),
          ),
          const SizedBox(height: 12),
          if (isLoadingPRs) const LinearProgressIndicator(color: Color(0xFFC8FF3D)),
          if (prs.isNotEmpty)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: Color(0xFF111720), borderRadius: BorderRadius.circular(12)),
              child: DropdownButton<Map<String, dynamic>>(
                value: selectedPR,
                isExpanded: true,
                dropdownColor: Color(0xFF1A1F2A),
                style: TextStyle(color: Colors.white),
                items: prs.map((pr) => DropdownMenuItem(value: pr, child: Text('PR #${pr['number']}: ${pr['title']} [${pr['branch']}]', overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() {
                  selectedPR = v;
                  branchCtrl.text = v!['branch'];
                }),
              ),
            ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: branchCtrl, style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'Branch (auto จาก PR)', filled: true, fillColor: Color(0xFF111720), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
            SizedBox(width: 12),
            FilledButton(onPressed: loadPRs, child: Text('โหลด PR')),
          ]),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Color(0xFFC8FF3D), foregroundColor: Colors.black, padding: EdgeInsets.all(16)),
            onPressed: isWriting? null : writePendingWork,
            icon: isWriting? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.auto_awesome),
            label: Text(isWriting? 'กำลังเขียน...' : 'เขียนงานค้างลง PR #${selectedPR?['number'] ?? ''} เลย'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: Color(0xFF111720), borderRadius: BorderRadius.circular(12)),
            child: EqMarkdownViewer(data: "```\n$log\n```"),
          ),
        ],
      ),
    );
  }
}
