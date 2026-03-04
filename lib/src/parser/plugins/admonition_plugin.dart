import '../ast/markdown_node.dart';
import '../parser_plugin.dart';

/// Types of admonition blocks
enum AdmonitionType {
  /// Note/info block
  note,

  /// Tip/hint block
  tip,

  /// Warning block
  warning,

  /// Danger/error block
  danger,

  /// Important block
  important,

  /// Custom type
  custom,
}

/// AST node representing an admonition block (callout/alert)
///
/// Admonitions are special block elements used to highlight
/// important information, warnings, tips, etc.
class AdmonitionNode extends MarkdownNode {
  /// Creates a new admonition node
  const AdmonitionNode({
    required this.admonitionType,
    required this.title,
    required this.children,
    this.customType,
  });

  /// The type of admonition
  final AdmonitionType admonitionType;

  /// Custom type name when [admonitionType] is [AdmonitionType.custom]
  final String? customType;

  /// The title of the admonition (may be empty)
  final String title;

  /// The content nodes inside the admonition
  final List<MarkdownNode> children;

  @override
  String get type => 'admonition';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'admonitionType': admonitionType.name,
        if (customType != null) 'customType': customType,
        'title': title,
        'children': children.map((c) => c.toJson()).toList(),
      };

  @override
  AdmonitionNode copyWith({
    AdmonitionType? admonitionType,
    String? customType,
    String? title,
    List<MarkdownNode>? children,
  }) {
    return AdmonitionNode(
      admonitionType: admonitionType ?? this.admonitionType,
      customType: customType ?? this.customType,
      title: title ?? this.title,
      children: children ?? this.children,
    );
  }

  @override
  String toString() =>
      'AdmonitionNode(type: $admonitionType, title: $title, children: ${children.length})';
}

/// Plugin for parsing admonition blocks (callouts/alerts)
///
/// Parses the following syntax:
/// ```markdown
/// ::: note Title
/// Content here
/// :::
///
/// ::: warning
/// Warning content
/// :::
///
/// ::: tip Custom Title
/// Tip content
/// :::
/// ```
///
/// Supported types: note, tip, warning, danger, important
/// Any other type will be treated as a custom type.
///
/// Example usage:
/// ```dart
/// final registry = ParserPluginRegistry();
/// registry.register(AdmonitionPlugin());
///
/// final parser = MarkdownParser(plugins: registry);
/// final nodes = parser.parse('''
/// ::: warning Important Notice
/// Please read carefully.
/// :::
/// ''');
/// ```
class AdmonitionPlugin extends BlockParserPlugin {
  /// Creates a new admonition plugin
  const AdmonitionPlugin();

  @override
  String get id => 'admonition';

  @override
  String get name => 'Admonition Plugin';

  @override
  int get priority => 10;

  /// Pattern for admonition start: `:::` type `[title]`
  static final RegExp _startPattern = RegExp(r'^:::\s*(\w+)(?:\s+(.+))?$');

  /// Pattern for admonition end: :::
  static final RegExp _endPattern = RegExp(r'^:::$');

  @override
  bool canParse(String line, List<String> lines, int index) {
    return _startPattern.hasMatch(line.trim());
  }

  @override
  BlockParseResult? parse(List<String> lines, int startIndex) {
    final firstLine = lines[startIndex].trim();
    final match = _startPattern.firstMatch(firstLine);

    if (match == null) {
      return null;
    }

    final typeStr = match.group(1)!.toLowerCase();
    final title = match.group(2)?.trim() ?? '';

    // Determine admonition type
    final admonitionType = _parseType(typeStr);
    final customType = admonitionType == AdmonitionType.custom ? typeStr : null;

    // Collect content lines until closing :::
    final contentLines = <String>[];
    var i = startIndex + 1;

    while (i < lines.length) {
      final line = lines[i].trim();

      if (_endPattern.hasMatch(line)) {
        // Found closing marker
        break;
      }

      contentLines.add(lines[i]);
      i++;
    }

    // Include the closing ::: in consumed lines
    final linesConsumed = i < lines.length ? i - startIndex + 1 : i - startIndex;

    // Parse content as nested markdown (simplified - just creates paragraph nodes)
    final children = _parseContent(contentLines);

    return BlockParseResult(
      node: AdmonitionNode(
        admonitionType: admonitionType,
        customType: customType,
        title: title,
        children: children,
      ),
      linesConsumed: linesConsumed,
    );
  }

  AdmonitionType _parseType(String type) {
    switch (type) {
      case 'note':
      case 'info':
        return AdmonitionType.note;
      case 'tip':
      case 'hint':
        return AdmonitionType.tip;
      case 'warning':
      case 'caution':
        return AdmonitionType.warning;
      case 'danger':
      case 'error':
        return AdmonitionType.danger;
      case 'important':
        return AdmonitionType.important;
      default:
        return AdmonitionType.custom;
    }
  }

  List<MarkdownNode> _parseContent(List<String> lines) {
    if (lines.isEmpty) {
      return [];
    }

    // Simple content parsing - just create paragraph nodes
    // In a real implementation, you might want to recursively parse
    final content = lines.join('\n').trim();
    if (content.isEmpty) {
      return [];
    }

    return [ParagraphNode([TextNode(content)])];
  }
}
