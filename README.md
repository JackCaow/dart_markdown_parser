# dart_markdown_parser

[![pub package](https://img.shields.io/pub/v/dart_markdown_parser.svg)](https://pub.dev/packages/dart_markdown_parser)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A pure Dart markdown parser that produces an Abstract Syntax Tree (AST). Zero external dependencies — works everywhere Dart runs: CLI, server, web, and Flutter.

## Installation

```yaml
dependencies:
  dart_markdown_parser: ^0.1.1
```

```bash
dart pub add dart_markdown_parser
```

## Features

- **CommonMark + GFM** — headers, paragraphs, lists, code blocks, tables, blockquotes, horizontal rules
- **Inline formatting** — bold, italic, strikethrough, inline code, links, images
- **Math formulas** — inline `$...$` and block `$$...$$`
- **Footnotes** — references `[^1]` and definitions `[^1]: ...`
- **Details/summary** — collapsible `<details>` blocks
- **Plugin system** — extend with custom block/inline syntax
- **LRU cache** — optional parse cache for repeated content
- **Immutable AST** — all nodes are immutable with `copyWith()` and `toJson()`

## Quick Start

```dart
import 'package:dart_markdown_parser/dart_markdown_parser.dart';

final parser = MarkdownParser();
final nodes = parser.parse('# Hello **World**');

for (final node in nodes) {
  print('${node.type}: ${node.toJson()}');
}
```

## Plugins

Register plugins for custom syntax:

```dart
final registry = ParserPluginRegistry();
registry.register(const MentionPlugin());   // @username
registry.register(const EmojiPlugin());     // :smile:
registry.register(const HashtagPlugin());   // #topic
registry.register(const AdmonitionPlugin());// ::: note
registry.register(const ThinkingPlugin());  // <thinking>
registry.register(const ArtifactPlugin());  // <artifact>
registry.register(const ToolCallPlugin());  // <tool_use>
registry.register(const MermaidPlugin());   // ```mermaid

final parser = MarkdownParser(plugins: registry);
```

## AST Nodes

| Node | Type String | Description |
|------|-------------|-------------|
| `HeaderNode` | `header` | H1-H6 with inline children |
| `ParagraphNode` | `paragraph` | Paragraph container |
| `TextNode` | `text` | Plain text |
| `BoldNode` | `bold` | **bold** |
| `ItalicNode` | `italic` | *italic* |
| `StrikethroughNode` | `strikethrough` | ~~strikethrough~~ |
| `InlineCodeNode` | `inline_code` | \`code\` |
| `CodeBlockNode` | `code_block` | Fenced code block |
| `LinkNode` | `link` | [text](url) |
| `ImageNode` | `image` | ![alt](url) |
| `ListNode` | `list` | Ordered/unordered list |
| `ListItemNode` | `list_item` | List item (with task list support) |
| `BlockquoteNode` | `blockquote` | > blockquote |
| `TableNode` | `table` | Table with alignment |
| `HorizontalRuleNode` | `horizontal_rule` | --- |
| `InlineMathNode` | `inline_math` | $latex$ |
| `BlockMathNode` | `block_math` | $$latex$$ |
| `FootnoteReferenceNode` | `footnote_reference` | [^label] |
| `FootnoteDefinitionNode` | `footnote_definition` | [^label]: content |
| `DetailsNode` | `details` | \<details\> block |

## Parse Cache

Use `MarkdownParseCache` to avoid re-parsing identical content:

```dart
final cache = MarkdownParseCache(maxSize: 100);
final parser = MarkdownParser();

// Check cache first
var nodes = cache.get(markdown);
if (nodes == null) {
  nodes = parser.parse(markdown);
  cache.put(markdown, nodes);
}
```

## License

MIT License — see [LICENSE](LICENSE) file for details.
