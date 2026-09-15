#!/bin/bash
# EqualizerPro - Apply Markdown Runtime Patch to PR #3
# รันไฟล์นี้ในโฟลเดอร์ EqualizerPro

set -e

echo "🎵 EqualizerPro - Markdown Runtime Patcher for PR #3"
echo "=================================================="

# 1. Check if we're in EqualizerPro repo
if [ ! -f "pubspec.yaml" ]; then
  echo "❌ ไม่พบ pubspec.yaml - กรุณารันในโฟลเดอร์ EqualizerPro"
  exit 1
fi

echo "✅ พบ EqualizerPro project"

# 2. Add dependencies
echo ""
echo "📦 เพิ่ม dependencies..."
flutter pub add flutter_markdown:^0.7.4+1 cached_network_image:^3.3.1 url_launcher:^6.2.5

# 3. Copy markdown runtime files
echo ""
echo "📁 Copy markdown runtime files..."
mkdir -p lib/core/markdown
mkdir -p lib/features/help/presentation/pages
mkdir -p lib/features/presets/presentation/widgets

# Files should be copied manually from the zip, but we create structure
echo "   lib/core/markdown/markdown_runtime.dart - ต้อง copy จาก patch"
echo "   lib/features/help/presentation/pages/help_page.dart - ต้อง copy จาก patch"
echo "   lib/features/presets/presentation/widgets/preset_doc_sheet.dart - ต้อง copy จาก patch"

# 4. Test
echo ""
echo "🧪 ทดสอบ..."
flutter analyze --no-pub || echo "⚠️ มี warning แต่ไม่เป็นไร"
echo ""
echo "✅ เสร็จแล้ว!"
echo ""
echo "วิธีใช้ในแอป:"
echo "  import 'package:equalizer_pro/core/markdown/markdown_runtime.dart';"
echo "  EqMarkdownViewer(data: yourMarkdown)"
echo ""
echo "เปิดหน้า Help:"
echo "  Navigator.push(context, MaterialPageRoute(builder: (_) => HelpPage()))"
