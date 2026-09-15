import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class EqMarkdownSanitizer {
  static const forbidden = ['script','iframe','form','style','onerror','onclick'];
  static String sanitize(String raw) {
    var t = raw;
    if (t.length > 102400) t = t.substring(0,102400);
    for (final tag in forbidden) {
      t = t.replaceAll(RegExp('<\[^>]*>.*?</\>', caseSensitive: false, dotAll: true), '');
      t = t.replaceAll(RegExp('<\[^>]*>', caseSensitive: false), '');
    }
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
      onTapLink: (text, href, title) async {
        if (href == null) return;
        final uri = Uri.tryParse(href);
        if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      imageBuilder: (uri, title, alt) {
        final url = uri.toString();
        if (!url.startsWith('https://')) return const SizedBox.shrink();
        return CachedNetworkImage(imageUrl: url, errorWidget: (c,u,e) => const Icon(Icons.broken_image));
      },
    );
  }
}
