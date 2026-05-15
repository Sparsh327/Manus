import 'markdown_block.dart';

/// Line-by-line state machine that splits a growing markdown string into
/// [MarkdownBlock]s. Completed blocks are emitted; the in-progress block
/// stays as [activeBlock].
class MarkdownParser {
  final List<MarkdownBlock> completedBlocks;
  final MarkdownBlock? activeBlock;

  const MarkdownParser({
    this.completedBlocks = const [],
    this.activeBlock,
  });

  factory MarkdownParser.initial() => const MarkdownParser();

  /// Feed the full (so-far) content string and return a new parser state
  /// derived from scratch. Called on every streaming token.
  static MarkdownParser parse(String fullContent) {
    final lines = fullContent.split('\n');
    final completed = <MarkdownBlock>[];
    MarkdownBlock? active;
    bool inCodeBlock = false;
    String? codeLang;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isLast = i == lines.length - 1;

      if (inCodeBlock) {
        if (line.trimRight() == '```') {
          // Close the code block.
          final code = active == null ? '' : active.content;
          completed.add(MarkdownBlock(
            type: BlockType.codeBlock,
            content: code,
            language: codeLang,
          ));
          active = null;
          inCodeBlock = false;
          codeLang = null;
        } else {
          active = active == null
              ? MarkdownBlock(
                  type: BlockType.codeBlock, content: line, language: codeLang)
              : active.appendLine(line);
        }
        continue;
      }

      // Opening fence
      if (line.startsWith('```')) {
        // Flush whatever was active before the fence.
        if (active != null) {
          completed.add(active);
          active = null;
        }
        inCodeBlock = true;
        final lang = line.substring(3).trim();
        codeLang = lang.isEmpty ? null : lang;
        continue;
      }

      final blockType = _classifyLine(line);

      if (line.trim().isEmpty) {
        // Blank line: complete the current block.
        if (active != null) {
          completed.add(active);
          active = null;
        }
        continue;
      }

      if (active == null) {
        active = MarkdownBlock(type: blockType, content: line);
      } else if (active.type == blockType ||
          _canContinue(active.type, blockType)) {
        active = active.appendLine(line);
      } else {
        // Type switch — flush current, start new.
        completed.add(active);
        active = MarkdownBlock(type: blockType, content: line);
      }

      // On every non-last completed line we can emit if the next line is
      // a type switch or blank — but we handle that above. For the last
      // line we keep it as active so the streaming bubble shows it live.
      if (!isLast && _isBlockTerminated(lines, i)) {
        completed.add(active);
        active = null;
      }
    }

    return MarkdownParser(
      completedBlocks: completed,
      activeBlock: active,
    );
  }

  static bool _isBlockTerminated(List<String> lines, int i) {
    if (i + 1 >= lines.length) return false;
    final next = lines[i + 1];
    if (next.trim().isEmpty) return true;
    final currentType = _classifyLine(lines[i]);
    final nextType = _classifyLine(next);
    return currentType != nextType && !_canContinue(currentType, nextType);
  }

  static BlockType _classifyLine(String line) {
    if (RegExp(r'^#{1,6}\s').hasMatch(line)) return BlockType.heading;
    if (line.startsWith('> ')) return BlockType.blockquote;
    if (RegExp(r'^[-*+]\s').hasMatch(line)) return BlockType.bulletList;
    if (RegExp(r'^\d+\.\s').hasMatch(line)) return BlockType.numberedList;
    if (line.trimRight() == '---' || line.trimRight() == '***') {
      return BlockType.horizontalRule;
    }
    return BlockType.paragraph;
  }

  static bool _canContinue(BlockType current, BlockType next) {
    // Paragraphs absorb consecutive paragraph lines.
    // Lists absorb consecutive same-type list lines.
    if (current == BlockType.paragraph && next == BlockType.paragraph) {
      return true;
    }
    if (current == BlockType.bulletList && next == BlockType.bulletList) {
      return true;
    }
    if (current == BlockType.numberedList && next == BlockType.numberedList) {
      return true;
    }
    return false;
  }
}
