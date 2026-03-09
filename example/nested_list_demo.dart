import 'package:dart_markdown_parser/dart_markdown_parser.dart';
import 'dart:convert';

void main() {
  final parser = MarkdownParser();

  // Example 1: Nested unordered list
  print('=== Example 1: Nested Unordered List ===');
  final markdown1 = '''- Item 1
  - Nested 1.1
  - Nested 1.2
    - Deep nested 1.2.1
- Item 2
  - Nested 2.1''';

  final nodes1 = parser.parse(markdown1);
  print(const JsonEncoder.withIndent('  ').convert(
    nodes1.map((n) => n.toJson()).toList(),
  ));

  // Example 2: Nested ordered list
  print('\n=== Example 2: Nested Ordered List ===');
  final markdown2 = '''1. First item
   1. Nested 1.1
   2. Nested 1.2
2. Second item
   1. Nested 2.1
   2. Nested 2.2''';

  final nodes2 = parser.parse(markdown2);
  print(const JsonEncoder.withIndent('  ').convert(
    nodes2.map((n) => n.toJson()).toList(),
  ));

  // Example 3: Mixed nested lists
  print('\n=== Example 3: Mixed Nested Lists ===');
  final markdown3 = '''- Unordered item
  1. Ordered nested
  2. Another ordered
    - Unordered deep nested
- Another unordered''';

  final nodes3 = parser.parse(markdown3);
  print(const JsonEncoder.withIndent('  ').convert(
    nodes3.map((n) => n.toJson()).toList(),
  ));

  // Example 4: Task list with nested items
  print('\n=== Example 4: Task List with Nested Items ===');
  final markdown4 = '''- [x] Completed task
  - [x] Nested completed
  - [ ] Nested todo
- [ ] Todo task
  - [ ] Nested todo''';

  final nodes4 = parser.parse(markdown4);
  print(const JsonEncoder.withIndent('  ').convert(
    nodes4.map((n) => n.toJson()).toList(),
  ));
}
