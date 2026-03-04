import '../ast/markdown_node.dart';
import '../parser_plugin.dart';

/// AST node for Mermaid diagrams
class MermaidDiagramNode extends MarkdownNode {
  /// Creates a new Mermaid diagram node
  const MermaidDiagramNode({
    required this.code,
    this.theme,
  });

  /// The Mermaid diagram code
  final String code;

  /// Optional theme name (light, dark, forest, neutral)
  final String? theme;

  @override
  String get type => 'mermaid';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'code': code,
        if (theme != null) 'theme': theme,
      };

  @override
  MermaidDiagramNode copyWith({String? code, String? theme}) {
    return MermaidDiagramNode(
      code: code ?? this.code,
      theme: theme ?? this.theme,
    );
  }

  @override
  String toString() =>
      'MermaidDiagramNode(code: ${code.substring(0, code.length > 30 ? 30 : code.length)}...)';
}

/// Plugin for parsing Mermaid code blocks in markdown
///
/// Detects code blocks with language `mermaid` and creates
/// [MermaidDiagramNode] instances for rendering.
///
/// Example markdown:
/// ````markdown
/// ```mermaid
/// graph TD
///   A[Start] --> B{Decision}
///   B -->|Yes| C[OK]
///   B -->|No| D[Cancel]
/// ```
/// ````
class MermaidPlugin extends BlockParserPlugin {
  /// Creates a Mermaid plugin
  const MermaidPlugin();

  @override
  String get id => 'mermaid';

  @override
  String get name => 'Mermaid Diagram Plugin';

  @override
  int get priority => 10; // Higher priority than default code blocks

  @override
  bool canParse(String line, List<String> lines, int index) {
    final trimmed = line.trim();
    return trimmed.startsWith('```mermaid') || trimmed.startsWith('~~~mermaid');
  }

  @override
  BlockParseResult? parse(List<String> lines, int startIndex) {
    final startLine = lines[startIndex].trim();

    // Determine fence character (``` or ~~~)
    final fenceChar = startLine.startsWith('```') ? '```' : '~~~';

    // Extract theme if specified: ```mermaid theme=dark
    String? theme;
    final themeMatch = RegExp(r'theme\s*=\s*(\w+)').firstMatch(startLine);
    if (themeMatch != null) {
      theme = themeMatch.group(1);
    }

    // Find the end of the code block
    final codeLines = <String>[];
    var linesConsumed = 1;

    for (var i = startIndex + 1; i < lines.length; i++) {
      final line = lines[i];
      linesConsumed++;

      if (line.trim().startsWith(fenceChar)) {
        // Found closing fence
        break;
      }

      codeLines.add(line);
    }

    if (codeLines.isEmpty) {
      return null;
    }

    final code = codeLines.join('\n').trim();

    return BlockParseResult(
      node: MermaidDiagramNode(
        code: code,
        theme: theme,
      ),
      linesConsumed: linesConsumed,
    );
  }
}
