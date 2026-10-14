import 'dart:math';

/// Three carved discs. Turns are free; submitting an alignment costs daylight.
class RuinsPuzzle {
  RuinsPuzzle({Random? random}) {
    final rng = random ?? Random();
    pattern = const [0, 1, 2];
    tiles = [for (final symbol in pattern) (symbol + 1 + rng.nextInt(3)) % 4];
  }

  RuinsPuzzle._(this.pattern, this.tiles, this.moves);

  static const symbolNames = ['Sun', 'Water', 'Leaf', 'Moon'];
  late final List<int> pattern;
  late final List<int> tiles;
  int moves = 0;
  bool get solved =>
      List.generate(3, (i) => tiles[i] == pattern[i]).every((v) => v);

  bool rotate(int index) {
    if (index < 0 || index >= tiles.length) return false;
    tiles[index] = (tiles[index] + 1) % symbolNames.length;
    moves++;
    return true;
  }

  Map<String, dynamic> toJson() => {
    'pattern': pattern,
    'tiles': tiles,
    'moves': moves,
  };

  factory RuinsPuzzle.fromJson(Map<String, dynamic> json) {
    final pattern = List<int>.from(json['pattern'] as List);
    final tiles = List<int>.from(json['tiles'] as List);
    final moves = json['moves'] as int;
    if (pattern.length != 3 ||
        tiles.length != 3 ||
        moves < 0 ||
        [...pattern, ...tiles].any((v) => v < 0 || v >= symbolNames.length)) {
      throw const FormatException('Invalid ruins puzzle');
    }
    return RuinsPuzzle._(List.unmodifiable(pattern), tiles, moves);
  }
}
