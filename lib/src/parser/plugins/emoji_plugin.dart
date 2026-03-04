import '../ast/markdown_node.dart';
import '../parser_plugin.dart';

/// AST node representing an emoji shortcode
class EmojiNode extends MarkdownNode {
  /// Creates a new emoji node
  const EmojiNode({
    required this.shortcode,
    required this.emoji,
  });

  /// The shortcode (without colons)
  final String shortcode;

  /// The resolved emoji character(s)
  final String emoji;

  @override
  String get type => 'emoji';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'shortcode': shortcode,
        'emoji': emoji,
      };

  @override
  EmojiNode copyWith({String? shortcode, String? emoji}) {
    return EmojiNode(
      shortcode: shortcode ?? this.shortcode,
      emoji: emoji ?? this.emoji,
    );
  }

  @override
  String toString() => 'EmojiNode(shortcode: $shortcode, emoji: $emoji)';
}

/// Plugin for parsing :emoji: shortcodes in markdown
///
/// Parses `:shortcode:` syntax into [EmojiNode] AST nodes.
///
/// Example usage:
/// ```dart
/// final registry = ParserPluginRegistry();
/// registry.register(EmojiPlugin());
///
/// final parser = MarkdownParser(plugins: registry);
/// final nodes = parser.parse('Hello :smile:!');
/// // Contains EmojiNode with shortcode: 'smile', emoji: '😄'
/// ```
///
/// You can customize the emoji map by extending this class or
/// providing a custom map to the constructor.
class EmojiPlugin extends InlineParserPlugin {
  /// Creates a new emoji plugin with optional custom emoji map
  ///
  /// If [customEmojis] is provided, it will be merged with the
  /// default emojis (custom emojis take precedence).
  const EmojiPlugin({Map<String, String>? customEmojis})
      : _customEmojis = customEmojis;

  final Map<String, String>? _customEmojis;

  /// Default emoji shortcode mappings
  static const Map<String, String> defaultEmojis = {
    // Smileys & Emotion
    'smile': '😄',
    'grinning': '😀',
    'laughing': '😆',
    'joy': '😂',
    'rofl': '🤣',
    'wink': '😉',
    'blush': '😊',
    'innocent': '😇',
    'heart_eyes': '😍',
    'star_struck': '🤩',
    'thinking': '🤔',
    'raised_eyebrow': '🤨',
    'neutral_face': '😐',
    'expressionless': '😑',
    'unamused': '😒',
    'roll_eyes': '🙄',
    'worried': '😟',
    'frowning': '😦',
    'cry': '😢',
    'sob': '😭',
    'angry': '😠',
    'rage': '😡',
    'skull': '💀',
    'poop': '💩',
    'clown': '🤡',
    'ghost': '👻',
    'alien': '👽',
    'robot': '🤖',
    'sunglasses': '😎',
    'nerd': '🤓',

    // Gestures
    'thumbsup': '👍',
    'thumbsdown': '👎',
    'ok_hand': '👌',
    'pinching_hand': '🤏',
    'wave': '👋',
    'clap': '👏',
    'pray': '🙏',
    'handshake': '🤝',
    'muscle': '💪',
    'point_up': '☝️',
    'point_down': '👇',
    'point_left': '👈',
    'point_right': '👉',
    'middle_finger': '🖕',
    'raised_hand': '✋',
    'vulcan_salute': '🖖',
    'fist': '✊',
    'punch': '👊',

    // Hearts & Love
    'heart': '❤️',
    'orange_heart': '🧡',
    'yellow_heart': '💛',
    'green_heart': '💚',
    'blue_heart': '💙',
    'purple_heart': '💜',
    'black_heart': '🖤',
    'white_heart': '🤍',
    'broken_heart': '💔',
    'sparkling_heart': '💖',
    'heartbeat': '💓',
    'two_hearts': '💕',
    'kiss': '💋',

    // Nature
    'sun': '☀️',
    'moon': '🌙',
    'star': '⭐',
    'cloud': '☁️',
    'rain': '🌧️',
    'snow': '❄️',
    'fire': '🔥',
    'rainbow': '🌈',
    'ocean': '🌊',
    'earth': '🌍',
    'tree': '🌳',
    'flower': '🌸',
    'rose': '🌹',

    // Animals
    'dog': '🐶',
    'cat': '🐱',
    'mouse': '🐭',
    'rabbit': '🐰',
    'fox': '🦊',
    'bear': '🐻',
    'panda': '🐼',
    'koala': '🐨',
    'tiger': '🐯',
    'lion': '🦁',
    'cow': '🐮',
    'pig': '🐷',
    'frog': '🐸',
    'monkey': '🐵',
    'chicken': '🐔',
    'penguin': '🐧',
    'bird': '🐦',
    'eagle': '🦅',
    'owl': '🦉',
    'butterfly': '🦋',
    'snail': '🐌',
    'bug': '🐛',
    'ant': '🐜',
    'bee': '🐝',
    'spider': '🕷️',
    'turtle': '🐢',
    'snake': '🐍',
    'dragon': '🐉',
    'whale': '🐳',
    'dolphin': '🐬',
    'fish': '🐟',
    'octopus': '🐙',
    'crab': '🦀',
    'unicorn': '🦄',

    // Food & Drink
    'apple': '🍎',
    'banana': '🍌',
    'grapes': '🍇',
    'watermelon': '🍉',
    'strawberry': '🍓',
    'peach': '🍑',
    'pizza': '🍕',
    'hamburger': '🍔',
    'fries': '🍟',
    'hotdog': '🌭',
    'taco': '🌮',
    'burrito': '🌯',
    'sushi': '🍣',
    'ramen': '🍜',
    'cake': '🎂',
    'cookie': '🍪',
    'chocolate': '🍫',
    'candy': '🍬',
    'icecream': '🍦',
    'coffee': '☕',
    'tea': '🍵',
    'beer': '🍺',
    'wine': '🍷',
    'cocktail': '🍸',

    // Activities
    'soccer': '⚽',
    'basketball': '🏀',
    'football': '🏈',
    'baseball': '⚾',
    'tennis': '🎾',
    'golf': '⛳',
    'trophy': '🏆',
    'medal': '🥇',
    'video_game': '🎮',
    'dart': '🎯',
    'bowling': '🎳',

    // Objects
    'phone': '📱',
    'computer': '💻',
    'keyboard': '⌨️',
    'camera': '📷',
    'tv': '📺',
    'radio': '📻',
    'book': '📖',
    'pen': '🖊️',
    'pencil': '✏️',
    'scissors': '✂️',
    'lock': '🔒',
    'key': '🔑',
    'hammer': '🔨',
    'wrench': '🔧',
    'bulb': '💡',
    'money': '💰',
    'gem': '💎',
    'gift': '🎁',
    'balloon': '🎈',

    // Symbols
    'check': '✅',
    'x': '❌',
    'warning': '⚠️',
    'question': '❓',
    'exclamation': '❗',
    'plus': '➕',
    'minus': '➖',
    '100': '💯',
    'sparkles': '✨',
    'boom': '💥',
    'zzz': '💤',
    'speech_balloon': '💬',
    'thought_balloon': '💭',

    // Flags & Misc
    'checkered_flag': '🏁',
    'triangular_flag': '🚩',
    'white_flag': '🏳️',
    'rainbow_flag': '🏳️‍🌈',
    'rocket': '🚀',
    'airplane': '✈️',
    'car': '🚗',
    'bus': '🚌',
    'train': '🚂',
    'ship': '🚢',
    'anchor': '⚓',
    'construction': '🚧',
  };

  @override
  String get id => 'emoji';

  @override
  String get name => 'Emoji Plugin';

  @override
  String get triggerCharacter => ':';

  @override
  int get priority => 5;

  /// Pattern for valid emoji shortcodes
  static final RegExp _shortcodePattern = RegExp(r'^([a-zA-Z0-9_]+):');

  @override
  bool canParse(String text, int index) {
    if (index >= text.length || text[index] != ':') {
      return false;
    }

    // Must have at least two characters after :
    if (index + 2 >= text.length) {
      return false;
    }

    // Next character must be alphanumeric or underscore
    final nextChar = text[index + 1];
    return RegExp(r'[a-zA-Z0-9_]').hasMatch(nextChar);
  }

  @override
  InlineParseResult? parse(String text, int startIndex) {
    if (startIndex >= text.length || text[startIndex] != ':') {
      return null;
    }

    // Extract the shortcode
    final remaining = text.substring(startIndex + 1);
    final match = _shortcodePattern.firstMatch(remaining);

    if (match == null) {
      return null;
    }

    final shortcode = match.group(1)!.toLowerCase();

    // Look up emoji
    var emoji = _customEmojis?[shortcode];
    emoji ??= defaultEmojis[shortcode];

    if (emoji == null) {
      // Unknown shortcode, don't parse
      return null;
    }

    return InlineParseResult(
      node: EmojiNode(
        shortcode: shortcode,
        emoji: emoji,
      ),
      consumed: 2 + shortcode.length, // : + shortcode + :
    );
  }
}
