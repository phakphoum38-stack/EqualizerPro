import 'package:flutter/material.dart';
import '../../../../core/markdown/markdown_runtime.dart';
class EqMarkdownWithPreview extends StatelessWidget {
  final String markdown;
  const EqMarkdownWithPreview({super.key, required this.markdown});
  @override
  Widget build(BuildContext context) => EqMarkdownViewer(data: markdown);
}
