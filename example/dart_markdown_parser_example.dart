import 'package:dart_markdown_parser/dart_markdown_parser.dart';

void main() {
  // === Basic Parsing ===
  print('=== Basic Parsing ===');
  final parser = MarkdownParser();
  final nodes = parser.parse('''
# Hello World

This is a **bold** and *italic* paragraph with `inline code`.

- Item 1
- Item 2
- Item 3

> A blockquote

| Name | Age |
| ---- | --- |
| Alice | 30 |
| Bob | 25 |

---

\$\$
E = mc^2
\$\$
''');

  print('Parsed ${nodes.length} top-level nodes:\n');
  for (final node in nodes) {
    print('  ${node.type}: $node');
  }

  // === Plugin System ===
  print('\n=== Plugin System ===');
  final registry = ParserPluginRegistry();
  registry.register(const MentionPlugin());
  registry.register(const EmojiPlugin());
  registry.register(const HashtagPlugin());

  final pluginParser = MarkdownParser(plugins: registry);
  final pluginNodes = pluginParser.parse(
    'Hello @john! Check out #flutter :rocket:',
  );

  print('Parsed with plugins:');
  for (final node in pluginNodes) {
    _printNode(node, indent: 2);
  }

  // === JSON Output ===
  print('\n=== JSON Output ===');
  final jsonNodes = parser.parse('**bold** and *italic*');
  for (final node in jsonNodes) {
    print('  ${node.toJson()}');
  }

  // === Parse Cache ===
  print('\n=== Parse Cache ===');
  final cache = MarkdownParseCache(maxSize: 50);
  const markdown = '# Cached Content';

  // First parse
  final parsed = parser.parse(markdown);
  cache.put(markdown, parsed);
  print('  Cached: ${cache.contains(markdown)}');
  print('  Cache size: ${cache.length}');

  // Cache hit
  final cached = cache.get(markdown);
  print('  Retrieved from cache: ${cached != null}');
  print('  Stats: ${cache.statistics}');
}

void _printNode(MarkdownNode node, {int indent = 0}) {
  final prefix = ' ' * indent;
  print('$prefix${node.type}: $node');

  if (node is ParagraphNode) {
    for (final child in node.children) {
      _printNode(child, indent: indent + 2);
    }
  }
}
