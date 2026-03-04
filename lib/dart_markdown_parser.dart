/// A pure Dart markdown parser with AST output.
///
/// Supports CommonMark, GFM extensions, math formulas, footnotes,
/// and an extensible plugin system. Zero external dependencies.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:dart_markdown_parser/dart_markdown_parser.dart';
///
/// final parser = MarkdownParser();
/// final nodes = parser.parse('# Hello **World**');
///
/// for (final node in nodes) {
///   print('${node.type}: ${node.toJson()}');
/// }
/// ```
///
/// ## Using Plugins
///
/// ```dart
/// final registry = ParserPluginRegistry();
/// registry.register(const MentionPlugin());
/// registry.register(const EmojiPlugin());
///
/// final parser = MarkdownParser(plugins: registry);
/// final nodes = parser.parse('Hello @john :smile:');
/// ```
library;

// Core AST
export 'src/parser/ast/markdown_node.dart';

// Parsers
export 'src/parser/markdown_parser.dart';
export 'src/parser/parse_cache.dart';

// Plugin system
export 'src/parser/parser_plugin.dart';

// Built-in plugins
export 'src/parser/plugins/admonition_plugin.dart';
export 'src/parser/plugins/artifact_plugin.dart';
export 'src/parser/plugins/emoji_plugin.dart';
export 'src/parser/plugins/hashtag_plugin.dart';
export 'src/parser/plugins/mention_plugin.dart';
export 'src/parser/plugins/mermaid_plugin.dart';
export 'src/parser/plugins/thinking_plugin.dart';
export 'src/parser/plugins/tool_call_plugin.dart';
