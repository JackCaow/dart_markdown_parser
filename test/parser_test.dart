import 'package:dart_markdown_parser/dart_markdown_parser.dart';
import 'package:test/test.dart';

void main() {
  late MarkdownParser parser;

  setUp(() {
    parser = MarkdownParser();
  });

  group('Basic parsing', () {
    test('empty input returns empty list', () {
      expect(parser.parse(''), isEmpty);
    });

    test('parses header', () {
      final nodes = parser.parse('# Hello');
      expect(nodes, hasLength(1));
      expect(nodes[0], isA<HeaderNode>());
      final header = nodes[0] as HeaderNode;
      expect(header.level, 1);
      expect(header.content, 'Hello');
    });

    test('parses H1-H6', () {
      for (var i = 1; i <= 6; i++) {
        final hashes = '#' * i;
        final nodes = parser.parse('$hashes Heading $i');
        expect(nodes, hasLength(1));
        final header = nodes[0] as HeaderNode;
        expect(header.level, i);
      }
    });

    test('parses paragraph', () {
      final nodes = parser.parse('Hello world');
      expect(nodes, hasLength(1));
      expect(nodes[0], isA<ParagraphNode>());
    });

    test('parses code block', () {
      final nodes = parser.parse('```dart\nprint("hello");\n```');
      expect(nodes, hasLength(1));
      expect(nodes[0], isA<CodeBlockNode>());
      final code = nodes[0] as CodeBlockNode;
      expect(code.language, 'dart');
      expect(code.code, 'print("hello");');
    });

    test('parses horizontal rule', () {
      for (final rule in ['---', '***', '___']) {
        final nodes = parser.parse(rule);
        expect(nodes, hasLength(1));
        expect(nodes[0], isA<HorizontalRuleNode>());
      }
    });
  });

  group('Inline parsing', () {
    test('parses bold text', () {
      final nodes = parser.parse('**bold**');
      expect(nodes, hasLength(1));
      final paragraph = nodes[0] as ParagraphNode;
      expect(paragraph.children, hasLength(1));
      expect(paragraph.children[0], isA<BoldNode>());
    });

    test('parses italic text', () {
      final nodes = parser.parse('*italic*');
      expect(nodes, hasLength(1));
      final paragraph = nodes[0] as ParagraphNode;
      expect(paragraph.children, hasLength(1));
      expect(paragraph.children[0], isA<ItalicNode>());
    });

    test('parses inline code', () {
      final nodes = parser.parse('use `code` here');
      expect(nodes, hasLength(1));
      final paragraph = nodes[0] as ParagraphNode;
      expect(paragraph.children.any((n) => n is InlineCodeNode), isTrue);
    });

    test('parses strikethrough', () {
      final nodes = parser.parse('~~deleted~~');
      expect(nodes, hasLength(1));
      final paragraph = nodes[0] as ParagraphNode;
      expect(paragraph.children, hasLength(1));
      expect(paragraph.children[0], isA<StrikethroughNode>());
    });

    test('parses link', () {
      final nodes = parser.parse('[text](https://example.com)');
      expect(nodes, hasLength(1));
      final paragraph = nodes[0] as ParagraphNode;
      expect(paragraph.children, hasLength(1));
      final link = paragraph.children[0] as LinkNode;
      expect(link.url, 'https://example.com');
    });

    test('parses image', () {
      final nodes = parser.parse('![alt](https://img.png)');
      expect(nodes, hasLength(1));
      final paragraph = nodes[0] as ParagraphNode;
      expect(paragraph.children, hasLength(1));
      final image = paragraph.children[0] as ImageNode;
      expect(image.url, 'https://img.png');
      expect(image.alt, 'alt');
    });

    test('parses inline math', () {
      final nodes = parser.parse(r'The formula $x^2$ is here');
      expect(nodes, hasLength(1));
      final paragraph = nodes[0] as ParagraphNode;
      expect(paragraph.children.any((n) => n is InlineMathNode), isTrue);
    });
  });

  group('Block elements', () {
    test('parses unordered list', () {
      final nodes = parser.parse('- Item 1\n- Item 2\n- Item 3');
      expect(nodes, hasLength(1));
      final list = nodes[0] as ListNode;
      expect(list.ordered, isFalse);
      expect(list.items, hasLength(3));
    });

    test('parses ordered list', () {
      final nodes = parser.parse('1. First\n2. Second\n3. Third');
      expect(nodes, hasLength(1));
      final list = nodes[0] as ListNode;
      expect(list.ordered, isTrue);
      expect(list.items, hasLength(3));
    });

    test('parses task list', () {
      final nodes = parser.parse('- [x] Done\n- [ ] Todo');
      expect(nodes, hasLength(1));
      final list = nodes[0] as ListNode;
      expect(list.items[0].checked, isTrue);
      expect(list.items[1].checked, isFalse);
    });

    test('parses nested unordered list', () {
      final markdown = '''- Item 1
  - Nested 1.1
  - Nested 1.2
- Item 2
  - Nested 2.1''';
      final nodes = parser.parse(markdown);
      expect(nodes, hasLength(1));
      final list = nodes[0] as ListNode;
      expect(list.items, hasLength(2));

      // Check first item has nested list
      final firstItem = list.items[0];
      expect(firstItem.children.any((n) => n is ListNode), isTrue);
      final nestedList = firstItem.children.firstWhere((n) => n is ListNode) as ListNode;
      expect(nestedList.items, hasLength(2));
    });

    test('parses nested ordered list', () {
      final markdown = '''1. First
   1. Nested 1.1
   2. Nested 1.2
2. Second''';
      final nodes = parser.parse(markdown);
      expect(nodes, hasLength(1));
      final list = nodes[0] as ListNode;
      expect(list.ordered, isTrue);
      expect(list.items, hasLength(2));

      // Check first item has nested list
      final firstItem = list.items[0];
      expect(firstItem.children.any((n) => n is ListNode), isTrue);
    });

    test('parses mixed nested lists', () {
      final markdown = '''- Unordered
  1. Ordered nested
  2. Another ordered
- Another unordered''';
      final nodes = parser.parse(markdown);
      expect(nodes, hasLength(1));
      final list = nodes[0] as ListNode;
      expect(list.ordered, isFalse);

      final firstItem = list.items[0];
      final nestedList = firstItem.children.firstWhere((n) => n is ListNode) as ListNode;
      expect(nestedList.ordered, isTrue);
    });

    test('parses blockquote', () {
      final nodes = parser.parse('> Quote text');
      expect(nodes, hasLength(1));
      expect(nodes[0], isA<BlockquoteNode>());
    });

    test('parses table', () {
      final nodes = parser.parse(
        '| H1 | H2 |\n| --- | --- |\n| A | B |',
      );
      expect(nodes, hasLength(1));
      final table = nodes[0] as TableNode;
      expect(table.headers, hasLength(2));
      expect(table.rows, hasLength(1));
    });

    test('parses block math', () {
      final nodes = parser.parse('\$\$\nE = mc^2\n\$\$');
      expect(nodes, hasLength(1));
      expect(nodes[0], isA<BlockMathNode>());
      final math = nodes[0] as BlockMathNode;
      expect(math.latex, 'E = mc^2');
    });

    test('parses footnote definition', () {
      final nodes = parser.parse('[^1]: Footnote content');
      expect(nodes, hasLength(1));
      expect(nodes[0], isA<FootnoteDefinitionNode>());
      final fn = nodes[0] as FootnoteDefinitionNode;
      expect(fn.label, '1');
    });

    test('parses footnote reference inline', () {
      final nodes = parser.parse('Text[^1] here');
      final paragraph = nodes[0] as ParagraphNode;
      expect(
        paragraph.children.any((n) => n is FootnoteReferenceNode),
        isTrue,
      );
    });
  });

  group('AST node operations', () {
    test('toJson roundtrip', () {
      final node = HeaderNode(level: 2, content: 'Test');
      final json = node.toJson();
      expect(json['type'], 'header');
      expect(json['level'], 2);
      expect(json['content'], 'Test');
    });

    test('copyWith creates modified copy', () {
      const node = TextNode('original');
      final copy = node.copyWith(content: 'modified');
      expect(copy.content, 'modified');
      expect(node.content, 'original');
    });

    test('type identifiers are correct', () {
      expect(const TextNode('').type, 'text');
      expect(HeaderNode(level: 1, content: '').type, 'header');
      expect(const ParagraphNode([]).type, 'paragraph');
      expect(const CodeBlockNode(code: '').type, 'code_block');
      expect(const HorizontalRuleNode().type, 'horizontal_rule');
      expect(const InlineCodeNode('').type, 'inline_code');
      expect(const BoldNode([]).type, 'bold');
      expect(const ItalicNode([]).type, 'italic');
      expect(const StrikethroughNode([]).type, 'strikethrough');
    });
  });

  group('Parse cache', () {
    test('stores and retrieves entries', () {
      final cache = MarkdownParseCache();
      final nodes = [const TextNode('test')];
      cache.put('# Test', nodes);
      expect(cache.get('# Test'), equals(nodes));
    });

    test('returns null for missing entries', () {
      final cache = MarkdownParseCache();
      expect(cache.get('missing'), isNull);
    });

    test('evicts LRU entries', () {
      final cache = MarkdownParseCache(maxSize: 2);
      cache.put('a', [const TextNode('a')]);
      cache.put('b', [const TextNode('b')]);
      cache.put('c', [const TextNode('c')]);
      expect(cache.contains('a'), isFalse);
      expect(cache.contains('b'), isTrue);
      expect(cache.contains('c'), isTrue);
    });

    test('clear removes all entries', () {
      final cache = MarkdownParseCache();
      cache.put('a', [const TextNode('a')]);
      cache.clear();
      expect(cache.isEmpty, isTrue);
    });
  });

  group('Plugin system', () {
    test('MentionPlugin parses @username', () {
      final registry = ParserPluginRegistry();
      registry.register(const MentionPlugin());
      final p = MarkdownParser(plugins: registry);

      final nodes = p.parse('Hello @john!');
      final paragraph = nodes[0] as ParagraphNode;
      expect(paragraph.children.any((n) => n is MentionNode), isTrue);
      final mention =
          paragraph.children.firstWhere((n) => n is MentionNode) as MentionNode;
      expect(mention.username, 'john');
    });

    test('HashtagPlugin parses #tag', () {
      final registry = ParserPluginRegistry();
      registry.register(const HashtagPlugin());
      final p = MarkdownParser(plugins: registry);

      final nodes = p.parse('Check #flutter');
      final paragraph = nodes[0] as ParagraphNode;
      expect(paragraph.children.any((n) => n is HashtagNode), isTrue);
      final hashtag =
          paragraph.children.firstWhere((n) => n is HashtagNode) as HashtagNode;
      expect(hashtag.tag, 'flutter');
    });

    test('EmojiPlugin parses :shortcode:', () {
      final registry = ParserPluginRegistry();
      registry.register(const EmojiPlugin());
      final p = MarkdownParser(plugins: registry);

      final nodes = p.parse('Hello :smile:');
      final paragraph = nodes[0] as ParagraphNode;
      expect(paragraph.children.any((n) => n is EmojiNode), isTrue);
      final emoji =
          paragraph.children.firstWhere((n) => n is EmojiNode) as EmojiNode;
      expect(emoji.shortcode, 'smile');
      expect(emoji.emoji, '😄');
    });

    test('AdmonitionPlugin parses ::: blocks', () {
      final registry = ParserPluginRegistry();
      registry.register(const AdmonitionPlugin());
      final p = MarkdownParser(plugins: registry);

      final nodes = p.parse('::: warning Alert\nContent\n:::');
      expect(nodes, hasLength(1));
      expect(nodes[0], isA<AdmonitionNode>());
      final admonition = nodes[0] as AdmonitionNode;
      expect(admonition.admonitionType, AdmonitionType.warning);
      expect(admonition.title, 'Alert');
    });

    test('ThinkingPlugin parses <thinking> blocks', () {
      final registry = ParserPluginRegistry();
      registry.register(const ThinkingPlugin());
      final p = MarkdownParser(plugins: registry);

      final nodes = p.parse('<thinking>\nReasoning here\n</thinking>');
      expect(nodes, hasLength(1));
      expect(nodes[0], isA<ThinkingNode>());
      final thinking = nodes[0] as ThinkingNode;
      expect(thinking.content, 'Reasoning here');
    });

    test('MermaidPlugin parses mermaid code blocks', () {
      final registry = ParserPluginRegistry();
      registry.register(const MermaidPlugin());
      final p = MarkdownParser(plugins: registry);

      final nodes = p.parse('```mermaid\ngraph TD\n  A-->B\n```');
      expect(nodes, hasLength(1));
      expect(nodes[0], isA<MermaidDiagramNode>());
    });

    test('plugin registry operations', () {
      final registry = ParserPluginRegistry();
      registry.register(const MentionPlugin());
      registry.register(const AdmonitionPlugin());

      expect(registry.inlinePlugins, hasLength(1));
      expect(registry.blockPlugins, hasLength(1));
      expect(registry.isInlineTrigger('@'), isTrue);
      expect(registry.isInlineTrigger('!'), isFalse);

      registry.unregisterInline('mention');
      expect(registry.inlinePlugins, isEmpty);
    });
  });

  group('parseBlocksOnly / parseInlineOnly', () {
    test('parseBlocksOnly returns raw blocks without inline processing', () {
      final nodes = parser.parseBlocksOnly('**bold** text');
      expect(nodes, hasLength(1));
      final paragraph = nodes[0] as ParagraphNode;
      // Should have raw TextNode without inline parsing
      expect(paragraph.children[0], isA<TextNode>());
    });

    test('parseInlineOnly parses inline elements', () {
      final nodes = parser.parseInlineOnly('**bold** and *italic*');
      expect(nodes.any((n) => n is BoldNode), isTrue);
      expect(nodes.any((n) => n is ItalicNode), isTrue);
    });
  });
}
