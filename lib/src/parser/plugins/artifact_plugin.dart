import '../ast/markdown_node.dart';
import '../parser_plugin.dart';

/// Types of artifacts that can be generated
enum ArtifactType {
  /// Code artifact (source code files)
  code,

  /// Document artifact (markdown, text)
  document,

  /// HTML artifact
  html,

  /// SVG/image artifact
  svg,

  /// React/Vue component
  component,

  /// Mermaid diagram
  mermaid,

  /// Unknown/custom type
  custom,
}

/// AST node representing an AI-generated artifact
///
/// Artifacts are standalone pieces of content (code, documents, etc.)
/// that can be displayed, copied, or downloaded separately.
///
/// Supports the Claude-style artifact syntax:
/// ```xml
/// <artifact identifier="unique-id" type="code" language="python" title="Hello World">
/// print("Hello, World!")
/// </artifact>
/// ```
class ArtifactNode extends MarkdownNode {
  /// Creates a new artifact node
  const ArtifactNode({
    required this.identifier,
    required this.artifactType,
    required this.content,
    this.title,
    this.language,
    this.customType,
  });

  /// Unique identifier for this artifact
  final String identifier;

  /// The type of artifact
  final ArtifactType artifactType;

  /// Custom type name when [artifactType] is [ArtifactType.custom]
  final String? customType;

  /// The artifact content
  final String content;

  /// Optional title for display
  final String? title;

  /// Programming language for code artifacts
  final String? language;

  @override
  String get type => 'artifact';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'identifier': identifier,
        'artifactType': artifactType.name,
        if (customType != null) 'customType': customType,
        'content': content,
        if (title != null) 'title': title,
        if (language != null) 'language': language,
      };

  @override
  ArtifactNode copyWith({
    String? identifier,
    ArtifactType? artifactType,
    String? customType,
    String? content,
    String? title,
    String? language,
  }) {
    return ArtifactNode(
      identifier: identifier ?? this.identifier,
      artifactType: artifactType ?? this.artifactType,
      customType: customType ?? this.customType,
      content: content ?? this.content,
      title: title ?? this.title,
      language: language ?? this.language,
    );
  }

  @override
  String toString() =>
      'ArtifactNode(id: $identifier, type: $artifactType, title: $title)';
}

/// Plugin for parsing AI-generated artifact blocks
///
/// Parses the Claude-style artifact syntax:
/// ```xml
/// <artifact identifier="my-code" type="code" language="python" title="Example">
/// def hello():
///     print("Hello!")
/// </artifact>
/// ```
///
/// Also supports simpler format:
/// ```xml
/// <artifact id="my-doc" type="document">
/// # My Document
/// Content here...
/// </artifact>
/// ```
///
/// Supported attributes:
/// - `identifier` or `id`: Unique identifier (required)
/// - `type`: Artifact type (code, document, html, svg, component, mermaid)
/// - `language`: Programming language for code artifacts
/// - `title`: Display title
///
/// Example usage:
/// ```dart
/// final registry = ParserPluginRegistry();
/// registry.register(ArtifactPlugin());
///
/// final parser = MarkdownParser(plugins: registry);
/// final nodes = parser.parse(artifactMarkdown);
/// ```
class ArtifactPlugin extends BlockParserPlugin {
  /// Creates a new artifact plugin
  const ArtifactPlugin();

  @override
  String get id => 'artifact';

  @override
  String get name => 'Artifact Plugin';

  @override
  int get priority => 20; // High priority for AI-specific syntax

  /// Pattern for artifact opening tag with attributes
  static final RegExp _startPattern = RegExp(
    r'^<artifact\s+(.+?)>\s*$',
    caseSensitive: false,
  );

  /// Pattern for artifact closing tag
  static final RegExp _endPattern = RegExp(
    r'^</artifact>\s*$',
    caseSensitive: false,
  );

  /// Pattern for extracting attributes
  static final RegExp _attrPattern = RegExp(
    r'''(\w+)=["']([^"']*)["']''',
  );

  @override
  bool canParse(String line, List<String> lines, int index) {
    return _startPattern.hasMatch(line.trim());
  }

  @override
  BlockParseResult? parse(List<String> lines, int startIndex) {
    final firstLine = lines[startIndex].trim();
    final startMatch = _startPattern.firstMatch(firstLine);

    if (startMatch == null) {
      return null;
    }

    // Parse attributes
    final attrString = startMatch.group(1)!;
    final attributes = _parseAttributes(attrString);

    // Get identifier (required)
    final identifier =
        attributes['identifier'] ?? attributes['id'] ?? 'unnamed';

    // Get artifact type
    final typeStr = attributes['type']?.toLowerCase() ?? 'custom';
    final artifactType = _parseType(typeStr);
    final customType = artifactType == ArtifactType.custom ? typeStr : null;

    // Get optional attributes
    final title = attributes['title'];
    final language = attributes['language'] ?? attributes['lang'];

    // Collect content lines until closing tag
    final contentLines = <String>[];
    var i = startIndex + 1;

    while (i < lines.length) {
      final line = lines[i].trim();

      if (_endPattern.hasMatch(line)) {
        // Found closing tag
        break;
      }

      contentLines.add(lines[i]);
      i++;
    }

    // Include the closing tag in consumed lines
    final linesConsumed =
        i < lines.length ? i - startIndex + 1 : i - startIndex;

    final content = contentLines.join('\n');

    return BlockParseResult(
      node: ArtifactNode(
        identifier: identifier,
        artifactType: artifactType,
        customType: customType,
        content: content,
        title: title,
        language: language,
      ),
      linesConsumed: linesConsumed,
    );
  }

  Map<String, String> _parseAttributes(String attrString) {
    final attributes = <String, String>{};

    for (final match in _attrPattern.allMatches(attrString)) {
      final key = match.group(1)!.toLowerCase();
      final value = match.group(2)!;
      attributes[key] = value;
    }

    return attributes;
  }

  ArtifactType _parseType(String type) {
    switch (type) {
      case 'code':
      case 'application/vnd.ant.code':
        return ArtifactType.code;
      case 'document':
      case 'text/markdown':
      case 'text/plain':
        return ArtifactType.document;
      case 'html':
      case 'text/html':
        return ArtifactType.html;
      case 'svg':
      case 'image/svg+xml':
        return ArtifactType.svg;
      case 'component':
      case 'application/vnd.ant.react':
        return ArtifactType.component;
      case 'mermaid':
        return ArtifactType.mermaid;
      default:
        return ArtifactType.custom;
    }
  }
}
