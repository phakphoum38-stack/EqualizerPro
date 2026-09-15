# EqualizerPro - Markdown Runtime Patch for PR #3

## สิ่งที่ Patch นี้ทำ

เพิ่ม Markdown Runtime ที่ปลอดภัยสำหรับ EqualizerPro เพื่อใช้แสดง:
- Help / Guide ใน Studio tab
- Preset descriptions (เช่น Bass Boost, Vocal)
- Changelog / Release notes
- AI Assistant ถ้ามีในอนาคต

## ไฟล์ที่เพิ่ม

```
lib/core/markdown/
└── markdown_runtime.dart   <- ไฟล์หลัก รวม Config + Sanitizer + Viewer
```

## วิธีติดตั้งใน PR #3

### 1. เพิ่ม dependencies ใน pubspec.yaml

เพิ่ม 3 บรรทัดนี้ใน dependencies:

```yaml
flutter_markdown: ^0.7.4+1
cached_network_image: ^3.3.1
url_launcher: ^6.2.5
```

### 2. Copy ไฟล์

```bash
cp lib/core/markdown/markdown_runtime.dart <your EqualizerPro>/lib/core/markdown/
```

### 3. ใช้งานใน App

#### ตัวอย่าง 1: หน้า Help ใน Studio Tab

```dart
// lib/features/studio/presentation/widgets/help_view.dart
import 'package:flutter/material.dart';
import 'package:equalizer_pro/core/markdown/markdown_runtime.dart';

class HelpView extends StatelessWidget {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: EqMarkdownViewer(data: """
# EqualizerPro Guide

Equalizer Pro เป็น **10-band parametric EQ** แบบ real-time

## การใช้งาน

- ลากไฟล์ MP3, WAV, OGG, FLAC เข้ามา
- ปรับ EQ 10 แบนด์ตามต้องการ
- เลือก 6 preset หรือ save custom profile

## DSP Effects

- **Bass Boost**: เพิ่มย่าน 60Hz
- **Reverb**: สร้างมิติเสียง
- **Stereo Width**: ขยายสเตอริโอ

> **WARNING:** อย่าเปิด gain เกิน +12dB

## YouTube

เปิด YouTube tab > Open YouTube / Google login > Paste link

ดูเพิ่มเติมที่ [GitHub](https://github.com/phakphoum38-stack/EqualizerPro)
"""),
    );
  }
}
```

#### ตัวอย่าง 2: Preset Description

```dart
EqPresetMarkdownCard(
  title: "Bass Boost",
  markdownDescription: """
**Bass Boost** เหมาะสำหรับเพลง EDM, Hip-Hop

- Low: 60Hz +6dB
- Mid: 250Hz -2dB
- High: 2kHz +1dB

```json
{
  "freq": 60,
  "gain": 6.0,
  "q": 1.2
}
```
""",
)
```

## Runtime Flow (ทำงานอัตโนมัติ)

```
Input -> Sanitizer (ตัด script/iframe, บังคับ https) -> Render (RepaintBoundary) -> Interaction (confirm link)
```

## Security สำหรับ EqualizerPro Web Build

- บล็อก http:// images อัตโนมัติ (ต้อง https เท่านั้น ไม่งั้น browser บล็อก)
- บล็อก <script>, <iframe> ทั้งหมด
- Link เปิดแบบ externalApplication ปลอดภัย

## CI

ไฟล์ .github/workflows/ci.yml ที่มีอยู่แล้วจะตรวจให้อัตโนมัติ
