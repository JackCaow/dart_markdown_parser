import 'dart:io';

import 'package:dart_markdown_parser/dart_markdown_parser.dart';

const _reset = '\x1B[0m';
const _bold = '\x1B[1m';
const _dim = '\x1B[2m';
const _cyan = '\x1B[36m';
const _green = '\x1B[32m';
const _yellow = '\x1B[33m';
const _magenta = '\x1B[35m';
const _red = '\x1B[31m';
const _blue = '\x1B[34m';

String _readStdin() {
  final buf = StringBuffer();
  String? line;
  while ((line = stdin.readLineSync()) != null) {
    buf.writeln(line);
  }
  return buf.toString();
}

void main(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final enablePlugins = args.contains('--plugins') || args.contains('-p');
  final jsonOutput = args.contains('--json') || args.contains('-j');
  final fileArgs = args.where((a) => !a.startsWith('-')).toList();

  String markdown;

  if (fileArgs.isNotEmpty) {
    final file = File(fileArgs.first);
    if (!file.existsSync()) {
      stderr.writeln('${_red}Error: File not found: ${fileArgs.first}$_reset');
      exit(1);
    }
    markdown = file.readAsStringSync();
    print('$_dim# Reading from: ${fileArgs.first}$_reset\n');
  } else if (!stdin.hasTerminal) {
    markdown = _readStdin();
  } else {
    print('$_bold${_cyan}dart_markdown_parser CLI Demo$_reset');
    print('${_dim}Enter markdown (Ctrl+D to finish):$_reset\n');
    markdown = _readStdin();
    print('');
  }

  // Create parser
  ParserPluginRegistry? registry;
  if (enablePlugins) {
    registry = ParserPluginRegistry();
    registry.registerAll(const [
      MentionPlugin(),
      HashtagPlugin(),
      EmojiPlugin(),
      AdmonitionPlugin(),
      ThinkingPlugin(),
      ArtifactPlugin(),
      ToolCallPlugin(),
      MermaidPlugin(),
    ]);
    print('$_dim# Plugins enabled: ${registry.blockPlugins.length} block, '
        '${registry.inlinePlugins.length} inline$_reset\n');
  }

  final parser = MarkdownParser(plugins: registry);

  // Benchmark
  final sw = Stopwatch()..start();
  final nodes = parser.parse(markdown);
  sw.stop();

  if (jsonOutput) {
    _printJson(nodes);
  } else {
    _printAst(nodes);
  }

  // Summary
  print('');
  print('$_dim─────────────────────────────────────$_reset');
  print('$_dim  Nodes: ${_countNodes(nodes)} total  '
      '│  Time: ${sw.elapsedMicroseconds}μs  '
      '│  Input: ${markdown.length} chars$_reset');
  print('$_dim─────────────────────────────────────$_reset');
}

void _printUsage() {
  print('''
${_bold}dart_markdown_parser CLI Demo$_reset

${_bold}Usage:$_reset
  dart run example/cli_demo.dart [options] [file]
  echo "# Hello" | dart run example/cli_demo.dart

${_bold}Options:$_reset
  -p, --plugins    Enable all built-in plugins
  -j, --json       Output AST as JSON
  -h, --help       Show this help

${_bold}Examples:$_reset
  dart run example/cli_demo.dart README.md
  dart run example/cli_demo.dart -p -j README.md
  echo "**bold** and *italic*" | dart run example/cli_demo.dart
''');
}

void _printAst(List<MarkdownNode> nodes, {int depth = 0}) {
  for (final node in nodes) {
    _printNodeTree(node, depth: depth);
  }
}

void _printNodeTree(MarkdownNode node, {int depth = 0}) {
  final indent = depth == 0 ? '' : '${'│  ' * (depth - 1)}├─ ';
  final color = _colorForType(node.type);
  final label = '$color${node.type}$_reset';

  switch (node) {
    case TextNode():
      final text = node.content.length > 60
          ? '${node.content.substring(0, 60)}...'
          : node.content;
      print('$indent$label $_dim"$text"$_reset');
    case HeaderNode():
      print('$indent$label ${_yellow}H${node.level}$_reset'
          ' $_dim"${node.content}"$_reset');
      if (node.children != null) {
        for (final child in node.children!) {
          _printNodeTree(child, depth: depth + 1);
        }
      }
    case ParagraphNode():
      print('$indent$label');
      for (final child in node.children) {
        _printNodeTree(child, depth: depth + 1);
      }
    case CodeBlockNode():
      final lang = node.language ?? 'plain';
      final preview = node.code.length > 40
          ? '${node.code.substring(0, 40)}...'
          : node.code;
      print('$indent$label $_green[$lang]$_reset $_dim"$preview"$_reset');
    case ListNode():
      final kind = node.ordered ? 'ordered' : 'unordered';
      print('$indent$label $_dim($kind, ${node.items.length} items)$_reset');
      for (final item in node.items) {
        _printNodeTree(item, depth: depth + 1);
      }
    case ListItemNode():
      final check = node.checked == null
          ? ''
          : node.checked! ? ' [x]' : ' [ ]';
      print('$indent$label$check');
      for (final child in node.children) {
        _printNodeTree(child, depth: depth + 1);
      }
    case BlockquoteNode():
      print('$indent$label');
      for (final child in node.children) {
        _printNodeTree(child, depth: depth + 1);
      }
    case TableNode():
      print('$indent$label $_dim(${node.headers.length} cols, '
          '${node.rows.length} rows)$_reset');
    case BoldNode():
      print('$indent$label');
      for (final child in node.children) {
        _printNodeTree(child, depth: depth + 1);
      }
    case ItalicNode():
      print('$indent$label');
      for (final child in node.children) {
        _printNodeTree(child, depth: depth + 1);
      }
    case StrikethroughNode():
      print('$indent$label');
      for (final child in node.children) {
        _printNodeTree(child, depth: depth + 1);
      }
    case LinkNode():
      print('$indent$label $_blue${node.url}$_reset');
      for (final child in node.children) {
        _printNodeTree(child, depth: depth + 1);
      }
    case ImageNode():
      print('$indent$label $_blue${node.url}$_reset'
          ' $_dim alt="${node.alt}"$_reset');
    case InlineCodeNode():
      print('$indent$label $_green`${node.code}`$_reset');
    case InlineMathNode():
      print('$indent$label $_magenta\$${node.latex}\$$_reset');
    case BlockMathNode():
      print('$indent$label $_magenta\$\$${node.latex}\$\$$_reset');
    case HorizontalRuleNode():
      print('$indent$label $_dim---$_reset');
    case FootnoteReferenceNode():
      print('$indent$label $_dim[^${node.label}]$_reset');
    case FootnoteDefinitionNode():
      print('$indent$label $_dim[^${node.label}]$_reset');
      for (final child in node.children) {
        _printNodeTree(child, depth: depth + 1);
      }
    case DetailsNode():
      print('$indent$label $_dim(open: ${node.isOpen})$_reset');
      for (final child in node.children) {
        _printNodeTree(child, depth: depth + 1);
      }
    // Plugin nodes
    case MentionNode():
      print('$indent$label $_cyan@${node.username}$_reset');
    case HashtagNode():
      print('$indent$label $_blue#${node.tag}$_reset');
    case EmojiNode():
      print('$indent$label ${node.emoji} $_dim:${node.shortcode}:$_reset');
    case AdmonitionNode():
      print('$indent$label $_yellow[${node.admonitionType.name}]$_reset'
          ' $_dim"${node.title}"$_reset');
      for (final child in node.children) {
        _printNodeTree(child, depth: depth + 1);
      }
    case ThinkingNode():
      final preview = node.content.length > 40
          ? '${node.content.substring(0, 40)}...'
          : node.content;
      print('$indent$label $_dim"$preview"$_reset');
    case MermaidDiagramNode():
      final preview = node.code.length > 40
          ? '${node.code.substring(0, 40)}...'
          : node.code;
      print('$indent$label $_dim"$preview"$_reset');
    case ArtifactNode():
      print('$indent$label $_dim[${node.artifactType.name}] '
          'id=${node.identifier}$_reset');
    case ToolCallNode():
      print('$indent$label $_dim${node.toolName} '
          '(${node.status.name})$_reset');
    default:
      print('$indent$label');
  }
}

String _colorForType(String type) {
  return switch (type) {
    'header' => _yellow,
    'paragraph' => _reset,
    'text' => _dim,
    'bold' || 'italic' || 'strikethrough' => _magenta,
    'code_block' || 'inline_code' => _green,
    'link' || 'image' => _blue,
    'list' || 'list_item' => _cyan,
    'blockquote' => _cyan,
    'table' => _cyan,
    'inline_math' || 'block_math' => _magenta,
    'horizontal_rule' => _dim,
    'mention' || 'hashtag' || 'emoji' => _cyan,
    'admonition' || 'thinking' || 'mermaid' => _yellow,
    'artifact' || 'tool_call' => _red,
    _ => _reset,
  };
}

void _printJson(List<MarkdownNode> nodes) {
  print('[');
  for (var i = 0; i < nodes.length; i++) {
    final comma = i < nodes.length - 1 ? ',' : '';
    _printJsonNode(nodes[i].toJson(), indent: 2);
    print(comma);
  }
  print(']');
}

void _printJsonNode(Map<String, dynamic> json, {int indent = 0}) {
  final prefix = ' ' * indent;
  stdout.write('$prefix{');
  final entries = json.entries.toList();
  for (var i = 0; i < entries.length; i++) {
    final e = entries[i];
    final comma = i < entries.length - 1 ? ', ' : '';
    stdout.write('"${e.key}": ${_jsonValue(e.value)}$comma');
  }
  stdout.write('}');
}

String _jsonValue(dynamic value) {
  if (value is String) return '"$value"';
  if (value is num || value is bool) return value.toString();
  if (value is List) return '[${value.map(_jsonValue).join(', ')}]';
  if (value is Map) {
    final pairs =
        value.entries.map((e) => '"${e.key}": ${_jsonValue(e.value)}');
    return '{${pairs.join(', ')}}';
  }
  return 'null';
}

int _countNodes(List<MarkdownNode> nodes) {
  var count = 0;
  for (final node in nodes) {
    count++;
    count += _countChildren(node);
  }
  return count;
}

int _countChildren(MarkdownNode node) {
  var count = 0;
  switch (node) {
    case ParagraphNode():
      count += _countNodes(node.children);
    case HeaderNode():
      if (node.children != null) count += _countNodes(node.children!);
    case ListNode():
      count += _countNodes(node.items);
    case ListItemNode():
      count += _countNodes(node.children);
    case BlockquoteNode():
      count += _countNodes(node.children);
    case BoldNode():
      count += _countNodes(node.children);
    case ItalicNode():
      count += _countNodes(node.children);
    case StrikethroughNode():
      count += _countNodes(node.children);
    case LinkNode():
      count += _countNodes(node.children);
    case FootnoteDefinitionNode():
      count += _countNodes(node.children);
    case DetailsNode():
      count += _countNodes(node.children);
    case AdmonitionNode():
      count += _countNodes(node.children);
    default:
      break;
  }
  return count;
}
