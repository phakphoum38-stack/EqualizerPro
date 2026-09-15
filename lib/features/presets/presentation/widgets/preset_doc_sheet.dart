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
      minChildSize: 0.3,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111720),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: Color(0xFF2B333F)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(20),
                  child: EqMarkdownViewer(data: doc),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
