import '../ast/markdown_node.dart';
import '../parser_plugin.dart';

/// AST node representing a hashtag (#tag)
class HashtagNode extends MarkdownNode {
  /// Creates a new hashtag node
  const HashtagNode(this.tag);

  /// The tag text (without the # symbol)
  final String tag;

  @override
  String get type => 'hashtag';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'tag': tag,
      };

  @override
  HashtagNode copyWith({String? tag}) {
    return HashtagNode(tag ?? this.tag);
  }

  @override
  String toString() => 'HashtagNode(tag: $tag)';
}

/// Plugin for parsing #hashtags in markdown
///
/// Parses `#tag` syntax into [HashtagNode] AST nodes.
///
/// Example usage:
/// ```dart
/// final registry = ParserPluginRegistry();
/// registry.register(HashtagPlugin());
///
/// final parser = MarkdownParser(plugins: registry);
/// final nodes = parser.parse('Check out #flutter!');
/// // Contains HashtagNode with tag: 'flutter'
/// ```
///
/// Tags must start with a letter or underscore and can contain
/// letters, numbers, and underscores.
class HashtagPlugin extends InlineParserPlugin {
  /// Creates a new hashtag plugin
  const HashtagPlugin();

  @override
  String get id => 'hashtag';

  @override
  String get name => 'Hashtag Plugin';

  @override
  String get triggerCharacter => '#';

  @override
  int get priority => 10;

  /// Pattern for valid hashtags
  static final RegExp _tagPattern = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*');

  @override
  bool canParse(String text, int index) {
    if (index >= text.length || text[index] != '#') {
      return false;
    }

    // Must have at least one character after #
    if (index + 1 >= text.length) {
      return false;
    }

    // Next character must be a letter or underscore
    final nextChar = text[index + 1];
    return RegExp(r'[a-zA-Z_]').hasMatch(nextChar);
  }

  @override
  InlineParseResult? parse(String text, int startIndex) {
    if (startIndex >= text.length || text[startIndex] != '#') {
      return null;
    }

    // Extract the tag
    final remaining = text.substring(startIndex + 1);
    final match = _tagPattern.firstMatch(remaining);

    if (match == null || match.group(0)!.isEmpty) {
      return null;
    }

    final tag = match.group(0)!;

    return InlineParseResult(
      node: HashtagNode(tag),
      consumed: 1 + tag.length, // # + tag
    );
  }
}
