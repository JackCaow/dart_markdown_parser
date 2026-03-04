import '../ast/markdown_node.dart';
import '../parser_plugin.dart';

/// AST node representing a user mention (@username)
class MentionNode extends MarkdownNode {
  /// Creates a new mention node
  const MentionNode(this.username);

  /// The username being mentioned (without the @ symbol)
  final String username;

  @override
  String get type => 'mention';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'username': username,
      };

  @override
  MentionNode copyWith({String? username}) {
    return MentionNode(username ?? this.username);
  }

  @override
  String toString() => 'MentionNode(username: $username)';
}

/// Plugin for parsing @mentions in markdown
///
/// Parses `@username` syntax into [MentionNode] AST nodes.
///
/// Example usage:
/// ```dart
/// final registry = ParserPluginRegistry();
/// registry.register(MentionPlugin());
///
/// final parser = MarkdownParser(plugins: registry);
/// final nodes = parser.parse('Hello @john!');
/// // Contains MentionNode with username: 'john'
/// ```
///
/// Usernames must start with a letter and can contain letters,
/// numbers, underscores, and hyphens.
class MentionPlugin extends InlineParserPlugin {
  /// Creates a new mention plugin
  const MentionPlugin();

  @override
  String get id => 'mention';

  @override
  String get name => 'Mention Plugin';

  @override
  String get triggerCharacter => '@';

  @override
  int get priority => 10; // Higher priority to check before other inline elements

  /// Pattern for valid usernames
  static final RegExp _usernamePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*');

  @override
  bool canParse(String text, int index) {
    if (index >= text.length || text[index] != '@') {
      return false;
    }

    // Must have at least one character after @
    if (index + 1 >= text.length) {
      return false;
    }

    // Next character must be a letter (start of username)
    final nextChar = text[index + 1];
    return RegExp(r'[a-zA-Z]').hasMatch(nextChar);
  }

  @override
  InlineParseResult? parse(String text, int startIndex) {
    if (startIndex >= text.length || text[startIndex] != '@') {
      return null;
    }

    // Extract the username
    final remaining = text.substring(startIndex + 1);
    final match = _usernamePattern.firstMatch(remaining);

    if (match == null || match.group(0)!.isEmpty) {
      return null;
    }

    final username = match.group(0)!;

    return InlineParseResult(
      node: MentionNode(username),
      consumed: 1 + username.length, // @ + username
    );
  }
}
