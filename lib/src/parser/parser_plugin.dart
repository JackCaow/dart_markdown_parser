import 'ast/markdown_node.dart';

/// Result of a block parsing operation
///
/// Contains the parsed node and the number of lines consumed
class BlockParseResult {
  /// Creates a new block parse result
  const BlockParseResult({
    required this.node,
    required this.linesConsumed,
  });

  /// The parsed node
  final MarkdownNode node;

  /// Number of lines consumed by this parse operation
  final int linesConsumed;
}

/// Result of an inline parsing operation
///
/// Contains the parsed node and the number of characters consumed
class InlineParseResult {
  /// Creates a new inline parse result
  const InlineParseResult({
    required this.node,
    required this.consumed,
  });

  /// The parsed node
  final MarkdownNode node;

  /// Number of characters consumed by this parse operation
  final int consumed;
}

/// Base interface for parser plugins
///
/// Parser plugins extend the markdown parser with custom syntax.
/// Implement either [BlockParserPlugin] or [InlineParserPlugin]
/// depending on the type of syntax you want to add.
abstract class ParserPlugin {
  /// Creates a new parser plugin
  const ParserPlugin();

  /// Unique identifier for this plugin
  String get id;

  /// Human-readable name for this plugin
  String get name;

  /// Priority of this plugin (higher = checked first)
  ///
  /// Default priority is 0. Built-in parsers use negative priorities
  /// so custom plugins are checked first by default.
  int get priority => 0;
}

/// Plugin for parsing block-level markdown elements
///
/// Block plugins handle multi-line constructs like custom containers,
/// admonitions, diagrams, etc.
///
/// Example implementing a custom admonition block:
/// ```dart
/// class AdmonitionPlugin extends BlockParserPlugin {
///   @override
///   String get id => 'admonition';
///
///   @override
///   String get name => 'Admonition Plugin';
///
///   @override
///   bool canParse(String line, List<String> lines, int index) {
///     return line.trim().startsWith(':::');
///   }
///
///   @override
///   BlockParseResult? parse(List<String> lines, int startIndex) {
///     // Parse admonition block...
///   }
/// }
/// ```
abstract class BlockParserPlugin extends ParserPlugin {
  /// Creates a new block parser plugin
  const BlockParserPlugin();

  /// Checks if this plugin can parse the given line
  ///
  /// Called for each line to determine if this plugin should
  /// attempt to parse starting from this position.
  ///
  /// [line] is the current line being checked
  /// [lines] is the full list of lines in the document
  /// [index] is the current line index
  bool canParse(String line, List<String> lines, int index);

  /// Parses a block starting at the given index
  ///
  /// Should return null if parsing fails after [canParse] returned true.
  /// This allows fallback to other parsers.
  ///
  /// [lines] is the full list of lines in the document
  /// [startIndex] is the index to start parsing from
  BlockParseResult? parse(List<String> lines, int startIndex);
}

/// Plugin for parsing inline markdown elements
///
/// Inline plugins handle text-level constructs like custom formatting,
/// emoji shortcodes, mentions, hashtags, etc.
///
/// Example implementing a mention plugin:
/// ```dart
/// class MentionPlugin extends InlineParserPlugin {
///   @override
///   String get id => 'mention';
///
///   @override
///   String get name => 'Mention Plugin';
///
///   @override
///   String get triggerCharacter => '@';
///
///   @override
///   bool canParse(String text, int index) {
///     return text[index] == '@';
///   }
///
///   @override
///   InlineParseResult? parse(String text, int startIndex) {
///     // Parse @username...
///   }
/// }
/// ```
abstract class InlineParserPlugin extends ParserPlugin {
  /// Creates a new inline parser plugin
  const InlineParserPlugin();

  /// The character(s) that trigger this plugin
  ///
  /// The parser will only call [canParse] when it encounters
  /// one of these characters. This improves performance.
  String get triggerCharacter;

  /// Checks if this plugin can parse starting at the given index
  ///
  /// [text] is the text being parsed
  /// [index] is the current character index
  bool canParse(String text, int index);

  /// Parses an inline element starting at the given index
  ///
  /// Should return null if parsing fails after [canParse] returned true.
  /// This allows fallback to other parsers.
  ///
  /// [text] is the text being parsed
  /// [startIndex] is the index to start parsing from
  InlineParseResult? parse(String text, int startIndex);
}

/// Registry for managing parser plugins
///
/// The registry maintains a collection of plugins and provides
/// methods to query them efficiently.
///
/// Example usage:
/// ```dart
/// final registry = ParserPluginRegistry();
/// registry.register(MentionPlugin());
/// registry.register(EmojiPlugin());
///
/// // Use with MarkdownParser
/// final parser = MarkdownParser(plugins: registry);
/// ```
class ParserPluginRegistry {
  /// Creates a new plugin registry
  ParserPluginRegistry();

  final List<BlockParserPlugin> _blockPlugins = [];
  final List<InlineParserPlugin> _inlinePlugins = [];
  final Map<String, InlineParserPlugin> _inlineTriggerMap = {};

  /// All registered block plugins, sorted by priority (descending)
  List<BlockParserPlugin> get blockPlugins =>
      List.unmodifiable(_blockPlugins);

  /// All registered inline plugins, sorted by priority (descending)
  List<InlineParserPlugin> get inlinePlugins =>
      List.unmodifiable(_inlinePlugins);

  /// Set of all inline trigger characters
  Set<String> get inlineTriggerCharacters =>
      _inlineTriggerMap.keys.toSet();

  /// Registers a block parser plugin
  ///
  /// Throws [ArgumentError] if a plugin with the same ID is already registered.
  void registerBlock(BlockParserPlugin plugin) {
    if (_blockPlugins.any((p) => p.id == plugin.id)) {
      throw ArgumentError('Block plugin with id "${plugin.id}" already registered');
    }
    _blockPlugins.add(plugin);
    _sortBlockPlugins();
  }

  /// Registers an inline parser plugin
  ///
  /// Throws [ArgumentError] if a plugin with the same ID is already registered.
  void registerInline(InlineParserPlugin plugin) {
    if (_inlinePlugins.any((p) => p.id == plugin.id)) {
      throw ArgumentError('Inline plugin with id "${plugin.id}" already registered');
    }
    _inlinePlugins.add(plugin);
    _inlineTriggerMap[plugin.triggerCharacter] = plugin;
    _sortInlinePlugins();
  }

  /// Registers a plugin (automatically determines type)
  void register(ParserPlugin plugin) {
    if (plugin is BlockParserPlugin) {
      registerBlock(plugin);
    } else if (plugin is InlineParserPlugin) {
      registerInline(plugin);
    } else {
      throw ArgumentError('Unknown plugin type: ${plugin.runtimeType}');
    }
  }

  /// Registers multiple plugins at once
  void registerAll(Iterable<ParserPlugin> plugins) {
    for (final plugin in plugins) {
      register(plugin);
    }
  }

  /// Unregisters a block plugin by ID
  ///
  /// Returns true if the plugin was found and removed.
  bool unregisterBlock(String id) {
    final index = _blockPlugins.indexWhere((p) => p.id == id);
    if (index >= 0) {
      _blockPlugins.removeAt(index);
      return true;
    }
    return false;
  }

  /// Unregisters an inline plugin by ID
  ///
  /// Returns true if the plugin was found and removed.
  bool unregisterInline(String id) {
    final index = _inlinePlugins.indexWhere((p) => p.id == id);
    if (index >= 0) {
      final plugin = _inlinePlugins.removeAt(index);
      _inlineTriggerMap.remove(plugin.triggerCharacter);
      return true;
    }
    return false;
  }

  /// Gets a block plugin by ID
  BlockParserPlugin? getBlockPlugin(String id) {
    for (final plugin in _blockPlugins) {
      if (plugin.id == id) return plugin;
    }
    return null;
  }

  /// Gets an inline plugin by ID
  InlineParserPlugin? getInlinePlugin(String id) {
    for (final plugin in _inlinePlugins) {
      if (plugin.id == id) return plugin;
    }
    return null;
  }

  /// Gets an inline plugin by trigger character
  InlineParserPlugin? getInlinePluginByTrigger(String char) {
    return _inlineTriggerMap[char];
  }

  /// Checks if a character is a trigger for any inline plugin
  bool isInlineTrigger(String char) {
    return _inlineTriggerMap.containsKey(char);
  }

  /// Finds block plugins that can parse the given line
  Iterable<BlockParserPlugin> findBlockPlugins(
    String line,
    List<String> lines,
    int index,
  ) sync* {
    for (final plugin in _blockPlugins) {
      if (plugin.canParse(line, lines, index)) {
        yield plugin;
      }
    }
  }

  /// Finds inline plugins that can parse at the given position
  Iterable<InlineParserPlugin> findInlinePlugins(String text, int index) sync* {
    if (index >= text.length) return;

    final char = text[index];
    for (final plugin in _inlinePlugins) {
      if (plugin.triggerCharacter == char && plugin.canParse(text, index)) {
        yield plugin;
      }
    }
  }

  /// Clears all registered plugins
  void clear() {
    _blockPlugins.clear();
    _inlinePlugins.clear();
    _inlineTriggerMap.clear();
  }

  /// Creates a copy of this registry
  ParserPluginRegistry copy() {
    final copy = ParserPluginRegistry();
    copy._blockPlugins.addAll(_blockPlugins);
    copy._inlinePlugins.addAll(_inlinePlugins);
    copy._inlineTriggerMap.addAll(_inlineTriggerMap);
    return copy;
  }

  void _sortBlockPlugins() {
    _blockPlugins.sort((a, b) => b.priority.compareTo(a.priority));
  }

  void _sortInlinePlugins() {
    _inlinePlugins.sort((a, b) => b.priority.compareTo(a.priority));
  }
}
