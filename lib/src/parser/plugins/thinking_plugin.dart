import '../ast/markdown_node.dart';
import '../parser_plugin.dart';

/// AST node representing AI thinking/reasoning content
///
/// Used to display AI's internal reasoning process, typically shown
/// in a collapsible or distinctly styled container.
///
/// Supports two formats:
/// - XML-style: `<thinking>...</thinking>` or `<think>...</think>`
/// - Markdown-style: `<|thinking|>...<|/thinking|>`
class ThinkingNode extends MarkdownNode {
  /// Creates a new thinking node
  const ThinkingNode({
    required this.content,
    this.isCollapsed = true,
  });

  /// The thinking/reasoning content
  final String content;

  /// Whether the thinking block should be collapsed by default
  final bool isCollapsed;

  @override
  String get type => 'thinking';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'content': content,
        'isCollapsed': isCollapsed,
      };

  @override
  ThinkingNode copyWith({
    String? content,
    bool? isCollapsed,
  }) {
    return ThinkingNode(
      content: content ?? this.content,
      isCollapsed: isCollapsed ?? this.isCollapsed,
    );
  }

  @override
  String toString() =>
      'ThinkingNode(content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content})';
}

/// Plugin for parsing AI thinking/reasoning blocks
///
/// Parses the following syntaxes:
/// ```markdown
/// <thinking>
/// AI's internal reasoning process...
/// </thinking>
///
/// <think>
/// Shorter alias for thinking blocks...
/// </think>
///
/// <|thinking|>
/// Alternative markdown-style syntax...
/// <|/thinking|>
/// ```
///
/// Example usage:
/// ```dart
/// final registry = ParserPluginRegistry();
/// registry.register(ThinkingPlugin());
///
/// final parser = MarkdownParser(plugins: registry);
/// final nodes = parser.parse('''
/// <thinking>
/// Let me analyze this problem step by step...
/// </thinking>
/// ''');
/// ```
class ThinkingPlugin extends BlockParserPlugin {
  /// Creates a new thinking plugin
  const ThinkingPlugin();

  @override
  String get id => 'thinking';

  @override
  String get name => 'Thinking Plugin';

  @override
  int get priority => 20; // High priority for AI-specific syntax

  /// Pattern for XML-style thinking start: `<thinking>` or `<think>`
  static final RegExp _xmlStartPattern =
      RegExp(r'^<(thinking|think)>\s*$', caseSensitive: false);

  /// Pattern for XML-style thinking end: `</thinking>` or `</think>`
  static final RegExp _xmlEndPattern =
      RegExp(r'^</(thinking|think)>\s*$', caseSensitive: false);

  /// Pattern for markdown-style thinking start: <|thinking|>
  static final RegExp _mdStartPattern =
      RegExp(r'^<\|(thinking|think)\|>\s*$', caseSensitive: false);

  /// Pattern for markdown-style thinking end: <|/thinking|>
  static final RegExp _mdEndPattern =
      RegExp(r'^<\|/(thinking|think)\|>\s*$', caseSensitive: false);

  @override
  bool canParse(String line, List<String> lines, int index) {
    final trimmed = line.trim();
    return _xmlStartPattern.hasMatch(trimmed) ||
        _mdStartPattern.hasMatch(trimmed);
  }

  @override
  BlockParseResult? parse(List<String> lines, int startIndex) {
    final firstLine = lines[startIndex].trim();

    // Determine which syntax is being used
    final isXmlStyle = _xmlStartPattern.hasMatch(firstLine);
    final isMdStyle = _mdStartPattern.hasMatch(firstLine);

    if (!isXmlStyle && !isMdStyle) {
      return null;
    }

    final endPattern = isXmlStyle ? _xmlEndPattern : _mdEndPattern;

    // Collect content lines until closing tag
    final contentLines = <String>[];
    var i = startIndex + 1;

    while (i < lines.length) {
      final line = lines[i].trim();

      if (endPattern.hasMatch(line)) {
        // Found closing tag
        break;
      }

      contentLines.add(lines[i]);
      i++;
    }

    // Include the closing tag in consumed lines
    final linesConsumed =
        i < lines.length ? i - startIndex + 1 : i - startIndex;

    final content = contentLines.join('\n').trim();

    return BlockParseResult(
      node: ThinkingNode(
        content: content,
        isCollapsed: true,
      ),
      linesConsumed: linesConsumed,
    );
  }
}
