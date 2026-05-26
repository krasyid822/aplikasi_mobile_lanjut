import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import '../../logic/models/message_model.dart';

class ChatBubble extends StatelessWidget {
  final MessageEntry message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: isUser ? Colors.indigo.shade700 : Colors.white,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: isUser 
          ? Text(
              message.text, 
              style: const TextStyle(color: Colors.white, fontSize: 15)
            )
          : MarkdownBody(
              data: message.text,
              selectable: true,
              builders: {
                'code': CodeElementBuilder(context),
              },
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(color: Colors.black87, fontSize: 15, height: 1.5),
                code: TextStyle(
                  backgroundColor: Colors.grey.shade200,
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Colors.deepOrange.shade900,
                ),
                codeblockDecoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
            ),
      ),
    );
  }
}

class CodeElementBuilder extends MarkdownElementBuilder {
  final BuildContext context;
  CodeElementBuilder(this.context);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final textContent = element.textContent;
    
    // Check if it's a code block (multiline) or inline code
    if (!textContent.contains('\n')) {
      return null; // Let the default builder handle inline code
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF282C34), // Dark code block style
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: const BoxDecoration(
              color: Color(0xFF21252B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Code Block",
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: textContent));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Kode berhasil disalin!"),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.copy, color: Colors.white70, size: 14),
                      SizedBox(width: 4),
                      Text("Copy", style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                textContent.trim(),
                style: const TextStyle(
                  color: Color(0xFFABB2BF), // Light grey text for dark theme
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MetricsPanel extends StatelessWidget {
  final int tokenCount;
  final double inferenceTime;
  const MetricsPanel({super.key, required this.tokenCount, required this.inferenceTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.indigo.shade900.withValues(alpha: 0.9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _item(Icons.speed, "$tokenCount tokens"),
          _item(Icons.timer, "${inferenceTime.toStringAsFixed(1)}s"),
          const Text("Thinking...", style: TextStyle(color: Colors.white, fontSize: 11, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String val) => Row(
    children: [
      Icon(icon, color: Colors.amber, size: 14),
      const SizedBox(width: 4),
      Text(val, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    ],
  );
}
