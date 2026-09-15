import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class EqMarkdownSanitizer {
  static String sanitize(String raw) {
    var t = raw;
    if (t.length > 150000) t = t.substring(0, 150000);
    t = t.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '');
    t = t.replaceAll(RegExp(r'<iframe[^>]*>.*?</iframe>', caseSensitive: false, dotAll: true), '');
    t = t.replaceAll(RegExp(r'<form[^>]*>.*?</form>', caseSensitive: false, dotAll: true), '');
    return t;
  }
}

class EqMarkdownViewer extends StatelessWidget {
  final String data;
  const EqMarkdownViewer({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: EqMarkdownSanitizer.sanitize(data),
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        h1: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFFC8FF3D)),
        h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        p: const TextStyle(height: 1.6, color: Colors.white, fontSize: 14.5),
        code: const TextStyle(fontFamily: 'monospace', backgroundColor: Color(0xFF1E1E1E)),
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFF1A1F2A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2B333F)),
        ),
        codeblockPadding: const EdgeInsets.all(14),
      ),
      onTapLink: (text, href, title) async {
        if (href == null) return;
        final uri = Uri.tryParse(href);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      imageBuilder: (uri, title, alt) {
        final url = uri.toString();
        if (!url.startsWith('https://')) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: url,
              placeholder: (c, u) => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
              errorWidget: (c, u, e) => const Icon(Icons.broken_image),
            ),
          ),
        );
      },
    );
  }
}
