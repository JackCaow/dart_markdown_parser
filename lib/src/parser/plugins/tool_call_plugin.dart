import '../ast/markdown_node.dart';
import '../parser_plugin.dart';

/// Status of a tool call
enum ToolCallStatus {
  /// Tool is currently executing
  running,

  /// Tool execution completed successfully
  completed,

  /// Tool execution failed
  failed,

  /// Tool execution was cancelled
  cancelled,

  /// Unknown/pending status
  pending,
}

/// AST node representing an AI tool/function call
///
/// Used to display tool invocations in AI chat interfaces,
/// showing the tool name, parameters, and optionally the result.
class ToolCallNode extends MarkdownNode {
  /// Creates a new tool call node
  const ToolCallNode({
    required this.toolName,
    this.toolId,
    this.parameters,
    this.result,
    this.status = ToolCallStatus.pending,
    this.errorMessage,
  });

  /// The name of the tool being called
  final String toolName;

  /// Optional unique identifier for this tool call
  final String? toolId;

  /// The parameters passed to the tool (as JSON string or Map)
  final dynamic parameters;

  /// The result of the tool call (if completed)
  final String? result;

  /// Current status of the tool call
  final ToolCallStatus status;

  /// Error message if the tool call failed
  final String? errorMessage;

  @override
  String get type => 'tool_call';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'toolName': toolName,
        if (toolId != null) 'toolId': toolId,
        if (parameters != null) 'parameters': parameters,
        if (result != null) 'result': result,
        'status': status.name,
        if (errorMessage != null) 'errorMessage': errorMessage,
      };

  @override
  ToolCallNode copyWith({
    String? toolName,
    String? toolId,
    dynamic parameters,
    String? result,
    ToolCallStatus? status,
    String? errorMessage,
  }) {
    return ToolCallNode(
      toolName: toolName ?? this.toolName,
      toolId: toolId ?? this.toolId,
      parameters: parameters ?? this.parameters,
      result: result ?? this.result,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() => 'ToolCallNode(name: $toolName, status: $status)';
}

/// Plugin for parsing AI tool/function call blocks
///
/// Supports parsing tool calls in XML format commonly used by AI assistants.
/// Parses `<tool_use>` blocks with tool name, id, and input parameters.
class ToolCallPlugin extends BlockParserPlugin {
  /// Creates a new tool call plugin
  const ToolCallPlugin();

  @override
  String get id => 'tool_call';

  @override
  String get name => 'Tool Call Plugin';

  @override
  int get priority => 25;

  // Pattern for tool_use block start
  static final RegExp _toolUseStartPattern = RegExp(
    r'^<tool_use>\s*$',
    caseSensitive: false,
  );

  static final RegExp _toolUseEndPattern = RegExp(
    r'^</tool_use>\s*$',
    caseSensitive: false,
  );

  // Pattern for extracting tool name
  static final RegExp _toolNamePattern = RegExp(
    r'<tool_name>([^<]+)</tool_name>',
    caseSensitive: false,
  );

  // Pattern for extracting tool id
  static final RegExp _toolIdPattern = RegExp(
    r'<tool_id>([^<]+)</tool_id>',
    caseSensitive: false,
  );

  @override
  bool canParse(String line, List<String> lines, int index) {
    return _toolUseStartPattern.hasMatch(line.trim());
  }

  @override
  BlockParseResult? parse(List<String> lines, int startIndex) {
    final firstLine = lines[startIndex].trim();

    if (!_toolUseStartPattern.hasMatch(firstLine)) {
      return null;
    }

    // Collect all content until closing tag
    final contentLines = <String>[];
    var i = startIndex + 1;

    while (i < lines.length) {
      final line = lines[i].trim();

      if (_toolUseEndPattern.hasMatch(line)) {
        break;
      }

      contentLines.add(lines[i]);
      i++;
    }

    final linesConsumed =
        i < lines.length ? i - startIndex + 1 : i - startIndex;

    final content = contentLines.join('\n');

    // Parse tool name
    final nameMatch = _toolNamePattern.firstMatch(content);
    final toolName = nameMatch?.group(1)?.trim() ?? 'unknown';

    // Parse tool id (optional)
    final idMatch = _toolIdPattern.firstMatch(content);
    final toolId = idMatch?.group(1)?.trim();

    // Parse input/parameters
    String? parameters;
    final inputStartIdx = content.indexOf('<input>');
    final inputEndIdx = content.indexOf('</input>');
    if (inputStartIdx != -1 && inputEndIdx != -1 && inputEndIdx > inputStartIdx) {
      parameters = content
          .substring(inputStartIdx + 7, inputEndIdx)
          .trim();
    }

    return BlockParseResult(
      node: ToolCallNode(
        toolName: toolName,
        toolId: toolId,
        parameters: parameters,
        status: ToolCallStatus.pending,
      ),
      linesConsumed: linesConsumed,
    );
  }
}
