import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manus/presentation/chat/widgets/streaming_markdown/code_block_widget.dart';
import 'package:manus/presentation/chat/widgets/streaming_markdown/markdown_block.dart';
import 'package:manus/presentation/chat/widgets/streaming_markdown/markdown_parser.dart';
import 'package:manus/theme/app_fonts.dart';
import 'package:manus/theme/app_text_styles.dart';

/// Entry point for rendering a completed (non-streaming) assistant message.
/// All blocks are rendered as [_CachedBlockWidget]s.
class StaticMarkdownView extends StatelessWidget {
  final String content;

  const StaticMarkdownView({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final parser = MarkdownParser.parse(content);
    final allBlocks = [
      ...parser.completedBlocks,
      if (parser.activeBlock != null) parser.activeBlock!,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < allBlocks.length; i++)
          _CachedBlockWidget(key: ValueKey(i), block: allBlocks[i]),
      ],
    );
  }
}

/// Entry point for rendering a live-streaming message.
/// [completedContent] is the finalized portion (displayed via cached blocks).
/// [streamingContent] is the in-progress token accumulation (rebuilt per token).
class StreamingMarkdownView extends StatefulWidget {
  final String streamingContent;

  const StreamingMarkdownView({super.key, required this.streamingContent});

  @override
  State<StreamingMarkdownView> createState() => _StreamingMarkdownViewState();
}

class _StreamingMarkdownViewState extends State<StreamingMarkdownView> {
  MarkdownParser _parser = MarkdownParser.initial();

  // Cache of completed blocks so we never rebuild them — only the active block
  // and the list tail need rebuilding.
  final List<_CachedBlockWidget> _cachedWidgets = [];
  int _lastCompletedCount = 0;

  @override
  void didUpdateWidget(StreamingMarkdownView old) {
    super.didUpdateWidget(old);
    if (old.streamingContent != widget.streamingContent) {
      _parser = MarkdownParser.parse(widget.streamingContent);
      // Append new completed blocks to cache — never touch existing ones.
      final completed = _parser.completedBlocks;
      for (var i = _lastCompletedCount; i < completed.length; i++) {
        _cachedWidgets.add(_CachedBlockWidget(key: ValueKey(i), block: completed[i]));
      }
      _lastCompletedCount = completed.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._cachedWidgets,
        if (_parser.activeBlock != null)
          _ActiveBlockWidget(block: _parser.activeBlock!),
      ],
    );
  }
}

/// A [StatefulWidget] whose [build] is called exactly once per block identity.
/// After the block is finalized (content won't change), it is never rebuilt.
class _CachedBlockWidget extends StatefulWidget {
  final MarkdownBlock block;

  const _CachedBlockWidget({super.key, required this.block});

  @override
  State<_CachedBlockWidget> createState() => _CachedBlockWidgetState();
}

class _CachedBlockWidgetState extends State<_CachedBlockWidget> {
  late Widget _built;

  @override
  void initState() {
    super.initState();
    _built = RepaintBoundary(child: _renderBlock(widget.block));
  }

  // No didUpdateWidget — intentional. We never update a completed block.

  @override
  Widget build(BuildContext context) => _built;
}

/// Renders the live in-progress block (rebuilt on every token).
/// Uses plain SelectableText for prose — avoids MarkdownBody parse overhead
/// on every token. Markdown formatting renders once the block is finalized
/// and promoted to a _CachedBlockWidget.
class _ActiveBlockWidget extends StatelessWidget {
  final MarkdownBlock block;

  const _ActiveBlockWidget({required this.block});

  @override
  Widget build(BuildContext context) {
    if (block.type == BlockType.codeBlock) {
      return CodeBlockWidget(code: block.content, language: block.language);
    }
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: SelectableText(
        block.content,
        style: AppTextStyles.body(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

Widget _renderBlock(MarkdownBlock block) {
  if (block.type == BlockType.codeBlock) {
    return CodeBlockWidget(code: block.content, language: block.language);
  }
  return Padding(
    padding: EdgeInsets.only(bottom: 4.h),
    child: _MarkdownBodyBlock(content: block.content),
  );
}

class _MarkdownBodyBlock extends StatelessWidget {
  final String content;

  const _MarkdownBodyBlock({required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: AppTextStyles.body(color: theme.colorScheme.onSurface),
        h1: AppTextStyles.h1(color: theme.colorScheme.onSurface),
        h2: AppTextStyles.h2(color: theme.colorScheme.onSurface),
        h3: AppTextStyles.h3(color: theme.colorScheme.onSurface),
        code: AppFonts.monospace(
          fontSize: 13,
          color: theme.colorScheme.onSurface,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: theme.colorScheme.primary, width: 3),
          ),
        ),
      ),
    );
  }
}
