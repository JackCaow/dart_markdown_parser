## 0.1.0

- Initial release
- Pure Dart markdown parser with AST output
- CommonMark + GFM support (headers, paragraphs, lists, code blocks, tables, blockquotes, horizontal rules)
- Inline formatting: bold, italic, strikethrough, inline code, links, images
- Math formula support (inline `$...$` and block `$$...$$`)
- Footnote references and definitions
- Details/summary collapsible blocks
- LRU parse cache for performance
- Extensible plugin system with 8 built-in plugins:
  - MentionPlugin (`@username`)
  - HashtagPlugin (`#tag`)
  - EmojiPlugin (`:shortcode:`)
  - AdmonitionPlugin (`:::` blocks)
  - ThinkingPlugin (`<thinking>` blocks)
  - ArtifactPlugin (`<artifact>` blocks)
  - ToolCallPlugin (`<tool_use>` blocks)
  - MermaidPlugin (` ```mermaid ` blocks)
