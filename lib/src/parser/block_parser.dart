import 'ast/markdown_node.dart';
import 'inline_parser.dart';
import 'parser_plugin.dart';

/// Parser for block-level Markdown elements
///
/// Handles parsing of:
/// - Headers (H1-H6)
/// - Paragraphs
/// - Lists (ordered/unordered)
/// - Blockquotes
/// - Code blocks
/// - Horizontal rules
/// - Tables
///
/// Supports custom block plugins through [ParserPluginRegistry].
class BlockParser {
  /// Creates a new block parser
  ///
  /// Optionally accepts a [ParserPluginRegistry] for custom block plugins.
  BlockParser({ParserPluginRegistry? plugins})
      : _plugins = plugins,
        _inlineParser = InlineParser(plugins: plugins);

  /// The inline parser for parsing cell contents
  final InlineParser _inlineParser;

  /// Plugin registry for custom block parsers
  final ParserPluginRegistry? _plugins;

  /// Parses a markdown text into a list of block-level nodes
  List<MarkdownNode> parse(String markdown) {
    if (markdown.isEmpty) {
      return [];
    }

    final lines = markdown.split('\n');
    final nodes = <MarkdownNode>[];
    var i = 0;

    while (i < lines.length) {
      final line = lines[i];

      // Skip empty lines at the start
      if (line.trim().isEmpty) {
        i++;
        continue;
      }

      // Try to parse different block types
      MarkdownNode? node;
      var consumed = 0;

      // Try plugins first (they have higher priority)
      if (_plugins != null) {
        final pluginResult = _tryParseWithPlugins(line, lines, i);
        if (pluginResult != null) {
          node = pluginResult.node;
          consumed = pluginResult.linesConsumed;
        }
      }

      // Try horizontal rule
      if (node == null && _isHorizontalRule(line)) {
        node = const HorizontalRuleNode();
        consumed = 1;
      }
      // Try header
      if (node == null && _isHeader(line)) {
        node = _parseHeader(line);
        consumed = 1;
      }
      // Try code block
      if (node == null && _isCodeBlockStart(line)) {
        final result = _parseCodeBlock(lines, i);
        node = result.node;
        consumed = result.linesConsumed;
      }
      // Try block math
      if (node == null && _isBlockMathStart(line)) {
        final result = _parseBlockMath(lines, i);
        node = result.node;
        consumed = result.linesConsumed;
      }
      // Try blockquote
      if (node == null && _isBlockquote(line)) {
        final result = _parseBlockquote(lines, i);
        node = result.node;
        consumed = result.linesConsumed;
      }
      // Try list
      if (node == null && _isListItem(line)) {
        final result = _parseList(lines, i);
        node = result.node;
        consumed = result.linesConsumed;
      }
      // Try footnote definition
      if (node == null && _isFootnoteDefinition(line)) {
        final result = _parseFootnoteDefinition(lines, i);
        node = result.node;
        consumed = result.linesConsumed;
      }
      // Try details block
      if (node == null && _isDetailsStart(line)) {
        final result = _parseDetails(lines, i);
        node = result.node;
        consumed = result.linesConsumed;
      }
      // Try table
      if (node == null && _isTableStart(lines, i)) {
        final result = _parseTable(lines, i);
        node = result.node;
        consumed = result.linesConsumed;
      }
      // Default: paragraph
      if (node == null) {
        final result = _parseParagraph(lines, i);
        node = result.node;
        consumed = result.linesConsumed;
      }

      nodes.add(node);
      i += consumed > 0 ? consumed : 1;
    }

    return nodes;
  }

  /// Checks if a line is a horizontal rule
  bool _isHorizontalRule(String line) {
    final trimmed = line.trim();
    if (trimmed.length < 3) return false;

    // Check for ---, ***, or ___
    final patterns = [
      RegExp(r'^-{3,}$'),
      RegExp(r'^\*{3,}$'),
      RegExp(r'^_{3,}$'),
    ];

    return patterns.any((pattern) => pattern.hasMatch(trimmed));
  }

  /// Checks if a line is a header
  bool _isHeader(String line) {
    return RegExp(r'^#{1,6}\s+.+').hasMatch(line);
  }

  /// Parses a header line
  HeaderNode _parseHeader(String line) {
    final match = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(line);
    if (match == null) {
      throw FormatException('Invalid header format: $line');
    }

    final level = match.group(1)!.length;
    final content = match.group(2)!.trim();

    // Parse inline formatting (bold, italic, links, etc.) in header content
    final children = _inlineParser.parse(content);

    return HeaderNode(
      level: level,
      content: content,
      children: children,
    );
  }

  /// Checks if a line starts a code block
  bool _isCodeBlockStart(String line) {
    return line.trim().startsWith('```');
  }

  /// Parses a code block
  _ParseResult _parseCodeBlock(List<String> lines, int startIndex) {
    final firstLine = lines[startIndex].trim();
    final language = firstLine.length > 3
        ? firstLine.substring(3).trim()
        : null;

    final codeLines = <String>[];
    var i = startIndex + 1;

    // Collect code lines until closing ```
    while (i < lines.length) {
      final line = lines[i];
      if (line.trim().startsWith('```')) {
        // Found closing fence
        return _ParseResult(
          node: CodeBlockNode(
            code: codeLines.join('\n'),
            language: language?.isEmpty ?? true ? null : language,
          ),
          linesConsumed: i - startIndex + 1,
        );
      }
      codeLines.add(line);
      i++;
    }

    // No closing fence found, treat as code block anyway
    return _ParseResult(
      node: CodeBlockNode(
        code: codeLines.join('\n'),
        language: language?.isEmpty ?? true ? null : language,
      ),
      linesConsumed: i - startIndex,
    );
  }

  /// Checks if a line starts a block math
  bool _isBlockMathStart(String line) {
    return line.trim().startsWith('\$\$');
  }

  /// Parses a block math
  _ParseResult _parseBlockMath(List<String> lines, int startIndex) {
    final mathLines = <String>[];
    var i = startIndex + 1;

    // Collect math lines until closing $$
    while (i < lines.length) {
      final line = lines[i];
      if (line.trim().startsWith('\$\$')) {
        // Found closing fence
        return _ParseResult(
          node: BlockMathNode(mathLines.join('\n')),
          linesConsumed: i - startIndex + 1,
        );
      }
      mathLines.add(line);
      i++;
    }

    // No closing fence found, treat as block math anyway
    return _ParseResult(
      node: BlockMathNode(mathLines.join('\n')),
      linesConsumed: i - startIndex,
    );
  }

  /// Checks if a line is a blockquote
  bool _isBlockquote(String line) {
    return line.trim().startsWith('>');
  }

  /// Parses a blockquote
  _ParseResult _parseBlockquote(List<String> lines, int startIndex) {
    final quoteLines = <String>[];
    var i = startIndex;

    // Collect all consecutive blockquote lines
    while (i < lines.length && _isBlockquote(lines[i])) {
      // Remove the > prefix and optional space
      final line = lines[i].trim();
      final content = line.startsWith('> ')
          ? line.substring(2)
          : line.substring(1);
      quoteLines.add(content);
      i++;
    }

    // Recursively parse the blockquote content
    final innerContent = quoteLines.join('\n');
    final innerNodes = parse(innerContent);

    return _ParseResult(
      node: BlockquoteNode(innerNodes),
      linesConsumed: i - startIndex,
    );
  }

  /// Checks if a line is a list item
  bool _isListItem(String line) {
    final trimmed = line.trim();
    // Unordered list: -, *, +
    if (RegExp(r'^[-*+]\s+').hasMatch(trimmed)) {
      return true;
    }
    // Ordered list: 1., 2., etc.
    if (RegExp(r'^\d+\.\s+').hasMatch(trimmed)) {
      return true;
    }
    return false;
  }

  /// Parses a list (ordered or unordered)
  _ParseResult _parseList(List<String> lines, int startIndex) {
    final firstLine = lines[startIndex].trim();
    final isOrdered = RegExp(r'^\d+\.').hasMatch(firstLine);

    final items = <ListItemNode>[];
    var i = startIndex;

    // Collect all consecutive list items
    while (i < lines.length) {
      final line = lines[i].trim();

      if (line.isEmpty) {
        i++;
        // Check if next line is still a list item
        if (i < lines.length && _isListItem(lines[i])) {
          continue;
        } else {
          break;
        }
      }

      if (!_isListItem(line)) {
        break;
      }

      // Check if list type matches
      final lineIsOrdered = RegExp(r'^\d+\.').hasMatch(line);
      if (lineIsOrdered != isOrdered) {
        break;
      }

      // Parse list item
      final item = _parseListItem(line);
      items.add(item);
      i++;
    }

    final startIndex0 = isOrdered
        ? _extractStartIndex(lines[startIndex].trim())
        : 1;

    return _ParseResult(
      node: ListNode(
        items: items,
        ordered: isOrdered,
        startIndex: startIndex0,
      ),
      linesConsumed: i - startIndex,
    );
  }

  /// Extracts the start index from an ordered list item
  int _extractStartIndex(String line) {
    final match = RegExp(r'^(\d+)\.').firstMatch(line);
    if (match == null) return 1;
    return int.tryParse(match.group(1)!) ?? 1;
  }

  /// Parses a single list item
  ListItemNode _parseListItem(String line) {
    // Remove list marker
    String content;
    bool? checked;

    if (RegExp(r'^[-*+]\s+').hasMatch(line)) {
      content = line.replaceFirst(RegExp(r'^[-*+]\s+'), '');

      // Check for task list
      if (content.startsWith('[ ] ')) {
        checked = false;
        content = content.substring(4);
      } else if (content.startsWith('[x] ') || content.startsWith('[X] ')) {
        checked = true;
        content = content.substring(4);
      }
    } else {
      content = line.replaceFirst(RegExp(r'^\d+\.\s+'), '');
    }

    return ListItemNode(
      children: [TextNode(content)],
      checked: checked,
    );
  }

  /// Checks if a line is a footnote definition
  ///
  /// Format: [^label]: content
  bool _isFootnoteDefinition(String line) {
    final trimmed = line.trim();
    return RegExp(r'^\[\^[^\]]+\]:\s+.+').hasMatch(trimmed);
  }

  /// Parses a footnote definition
  ///
  /// Format: [^label]: content (can span multiple indented lines)
  _ParseResult _parseFootnoteDefinition(List<String> lines, int startIndex) {
    final firstLine = lines[startIndex].trim();
    final match = RegExp(r'^\[\^([^\]]+)\]:\s+(.+)$').firstMatch(firstLine);

    if (match == null) {
      throw FormatException('Invalid footnote format: $firstLine');
    }

    final label = match.group(1)!;
    final contentLines = <String>[match.group(2)!];
    var i = startIndex + 1;

    // Collect continuation lines (indented lines)
    while (i < lines.length) {
      final line = lines[i];

      // Empty line might be part of footnote
      if (line.trim().isEmpty) {
        i++;
        continue;
      }

      // Check if line is indented (continuation of footnote)
      if (line.startsWith('    ') || line.startsWith('\t')) {
        contentLines.add(line.trim());
        i++;
      } else {
        // Not indented, footnote definition ends
        break;
      }
    }

    // Parse the content as inline elements
    final content = contentLines.join(' ');
    final children = _inlineParser.parse(content);

    return _ParseResult(
      node: FootnoteDefinitionNode(
        label: label,
        children: children,
      ),
      linesConsumed: i - startIndex,
    );
  }

  /// Parses a paragraph
  _ParseResult _parseParagraph(List<String> lines, int startIndex) {
    final paragraphLines = <String>[];
    var i = startIndex;

    // Collect consecutive non-empty lines that don't start special blocks
    while (i < lines.length) {
      final line = lines[i];

      // Stop at empty line
      if (line.trim().isEmpty) {
        break;
      }

      // Stop at special block markers
      if (_isHeader(line) ||
          _isCodeBlockStart(line) ||
          _isBlockquote(line) ||
          _isListItem(line) ||
          _isHorizontalRule(line) ||
          _isFootnoteDefinition(line) ||
          _isTableStart(lines, i)) {
        break;
      }

      paragraphLines.add(line);
      i++;
    }

    final content = paragraphLines.join('\n');

    return _ParseResult(
      node: ParagraphNode([TextNode(content)]),
      linesConsumed: i - startIndex,
    );
  }

  /// Checks if a line starts a table (header followed by separator)
  bool _isTableStart(List<String> lines, int index) {
    if (index >= lines.length) return false;

    final line = lines[index].trim();
    if (!line.contains('|')) return false;

    // Check if next line is a separator line
    if (index + 1 >= lines.length) return false;
    final nextLine = lines[index + 1].trim();

    return _isTableSeparator(nextLine);
  }

  /// Checks if a line is a table separator (e.g., |---|---|)
  bool _isTableSeparator(String line) {
    if (!line.contains('|')) return false;

    // Remove leading/trailing pipes and split
    var trimmed = line.trim();
    if (trimmed.startsWith('|')) trimmed = trimmed.substring(1);
    if (trimmed.endsWith('|')) trimmed = trimmed.substring(0, trimmed.length - 1);

    final parts = trimmed.split('|');
    if (parts.isEmpty) return false;

    // Each part should be a separator like ---, :---, ---:, or :---:
    final separatorPattern = RegExp(r'^\s*:?-+:?\s*$');
    return parts.every((part) => separatorPattern.hasMatch(part));
  }

  /// Parses a table
  _ParseResult _parseTable(List<String> lines, int startIndex) {
    if (startIndex + 1 >= lines.length) {
      throw const FormatException('Invalid table: missing separator line');
    }

    // Parse header row
    final headerLine = lines[startIndex].trim();
    final headerCells = _parseTableRow(headerLine);

    // Parse separator row to get alignments
    final separatorLine = lines[startIndex + 1].trim();
    final alignments = _parseTableAlignments(separatorLine);

    // Ensure alignments match header count
    while (alignments.length < headerCells.length) {
      alignments.add(null);
    }

    // Parse data rows
    final rows = <TableRowNode>[];
    var i = startIndex + 2;

    while (i < lines.length) {
      final line = lines[i].trim();

      // Stop at empty line or non-table line
      if (line.isEmpty || !line.contains('|')) {
        break;
      }

      final cells = _parseTableRow(line);
      rows.add(TableRowNode(cells));
      i++;
    }

    return _ParseResult(
      node: TableNode(
        headers: headerCells,
        alignments: alignments,
        rows: rows,
      ),
      linesConsumed: i - startIndex,
    );
  }

  /// Parses a table row into cells
  List<List<MarkdownNode>> _parseTableRow(String line) {
    var trimmed = line.trim();

    // Remove leading/trailing pipes
    if (trimmed.startsWith('|')) trimmed = trimmed.substring(1);
    if (trimmed.endsWith('|')) trimmed = trimmed.substring(0, trimmed.length - 1);

    // Split by pipe
    final parts = trimmed.split('|');

    // Parse each cell's content
    return parts.map((cell) {
      final content = cell.trim();
      if (content.isEmpty) {
        return <MarkdownNode>[const TextNode('')];
      }
      // Parse inline elements in cell
      return _inlineParser.parse(content);
    }).toList();
  }

  /// Parses table column alignments from separator row
  List<TableAlignment?> _parseTableAlignments(String line) {
    var trimmed = line.trim();

    // Remove leading/trailing pipes
    if (trimmed.startsWith('|')) trimmed = trimmed.substring(1);
    if (trimmed.endsWith('|')) trimmed = trimmed.substring(0, trimmed.length - 1);

    final parts = trimmed.split('|');

    return parts.map((part) {
      final cleaned = part.trim();
      final startsWithColon = cleaned.startsWith(':');
      final endsWithColon = cleaned.endsWith(':');

      if (startsWithColon && endsWithColon) {
        return TableAlignment.center;
      } else if (endsWithColon) {
        return TableAlignment.right;
      } else if (startsWithColon) {
        return TableAlignment.left;
      } else {
        return null; // Default alignment
      }
    }).toList();
  }

  /// Checks if a line starts a details block
  ///
  /// Format: `<details>` or `<details open>`
  bool _isDetailsStart(String line) {
    final trimmed = line.trim().toLowerCase();
    return trimmed == '<details>' || trimmed == '<details open>';
  }

  /// Parses a details block
  ///
  /// Format:
  /// `<details>`
  /// `<summary>`Summary text`</summary>`
  /// Content here
  /// `</details>`
  _ParseResult _parseDetails(List<String> lines, int startIndex) {
    final firstLine = lines[startIndex].trim().toLowerCase();
    final isOpen = firstLine.contains('open');

    var i = startIndex + 1;
    var summary = <MarkdownNode>[const TextNode('')];
    final contentLines = <String>[];
    var foundSummary = false;
    var inSummary = false;

    // Parse the details block
    while (i < lines.length) {
      final line = lines[i];
      final trimmedLower = line.trim().toLowerCase();

      // Check for closing details tag
      if (trimmedLower == '</details>') {
        break;
      }

      // Check for summary tag
      if (trimmedLower.startsWith('<summary>')) {
        inSummary = true;
        foundSummary = true;

        // Extract summary content from same line if present
        final summaryContent = line.trim().substring(9); // Remove <summary>
        if (summaryContent.toLowerCase().contains('</summary>')) {
          // Summary closes on same line
          final endIndex = summaryContent.toLowerCase().indexOf('</summary>');
          final summaryText = summaryContent.substring(0, endIndex).trim();
          summary = _inlineParser.parse(summaryText);
          inSummary = false;
        } else if (summaryContent.isNotEmpty) {
          // Summary continues
          summary = _inlineParser.parse(summaryContent);
        }
        i++;
        continue;
      }

      // Check for closing summary tag
      if (inSummary && trimmedLower.contains('</summary>')) {
        final endIndex = line.toLowerCase().indexOf('</summary>');
        final summaryText = line.substring(0, endIndex).trim();
        if (summaryText.isNotEmpty) {
          summary = _inlineParser.parse(summaryText);
        }
        inSummary = false;
        i++;
        continue;
      }

      // If still in summary, add to summary
      if (inSummary) {
        var existingSummary = '';
        if (summary.isNotEmpty && summary.first is TextNode) {
          existingSummary = (summary.first as TextNode).content;
        }
        summary = _inlineParser.parse('$existingSummary ${line.trim()}');
        i++;
        continue;
      }

      // Otherwise, add to content
      if (foundSummary) {
        contentLines.add(line);
      }
      i++;
    }

    // Parse the content
    final children = contentLines.isEmpty
        ? <MarkdownNode>[]
        : parse(contentLines.join('\n'));

    return _ParseResult(
      node: DetailsNode(
        summary: summary,
        children: children,
        isOpen: isOpen,
      ),
      linesConsumed: i - startIndex + 1,
    );
  }

  /// Tries to parse using registered plugins
  ///
  /// Returns null if no plugin can parse the current line.
  BlockParseResult? _tryParseWithPlugins(
    String line,
    List<String> lines,
    int index,
  ) {
    final plugins = _plugins;
    if (plugins == null) return null;

    for (final plugin in plugins.blockPlugins) {
      if (plugin.canParse(line, lines, index)) {
        final result = plugin.parse(lines, index);
        if (result != null) {
          return result;
        }
      }
    }
    return null;
  }
}

/// Result of parsing operation
class _ParseResult {
  const _ParseResult({
    required this.node,
    required this.linesConsumed,
  });

  final MarkdownNode node;
  final int linesConsumed;
}
