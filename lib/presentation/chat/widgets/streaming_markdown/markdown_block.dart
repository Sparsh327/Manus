enum BlockType {
  paragraph,
  heading,
  codeBlock,
  bulletList,
  numberedList,
  blockquote,
  horizontalRule,
}

class MarkdownBlock {
  final BlockType type;
  final String content;
  final String? language; // for codeBlock only

  const MarkdownBlock({
    required this.type,
    required this.content,
    this.language,
  });

  MarkdownBlock appendLine(String line) => MarkdownBlock(
        type: type,
        content: content.isEmpty ? line : '$content\n$line',
        language: language,
      );

  bool get isComplete => true;

  @override
  String toString() => 'MarkdownBlock($type, ${content.length} chars)';
}
