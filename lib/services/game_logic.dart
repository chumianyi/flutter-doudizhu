import '../models/card.dart';

enum CardType {
  single, pair, triple, tripleWithSingle, tripleWithPair,
  straight, consecutivePairs, airplane, airplaneWithSingles, airplaneWithPairs,
  fourWithTwoSingles, fourWithTwoPairs, bomb, rocket, invalid
}

class CardCombo {
  final CardType type;
  final List<PlayingCard> cards;
  final int mainValue;
  final int length;

  const CardCombo({
    required this.type,
    required this.cards,
    required this.mainValue,
    required this.length,
  });
}

class GameLogic {
  static CardCombo? analyzeCards(List<PlayingCard> input) {
    if (input.isEmpty) return null;
    final cards = List<PlayingCard>.from(input)
      ..sort((a, b) => a.rank.value.compareTo(b.rank.value));

    // 王炸
    if (cards.length == 2 &&
        cards.any((c) => c.rank == CardRank.smallJoker) &&
        cards.any((c) => c.rank == CardRank.bigJoker)) {
      return CardCombo(type: CardType.rocket, cards: cards, mainValue: 100, length: 2);
    }

    // 按点数分组
    final Map<int, List<PlayingCard>> groups = {};
    for (final c in cards) {
      groups.putIfAbsent(c.rank.value, () => []).add(c);
    }
    final sortedKeys = groups.keys.toList()..sort();
    final counts = sortedKeys.map((k) => groups[k]!.length).toList();

    // 炸弹
    if (cards.length == 4 && counts.every((c) => c == 4)) {
      return CardCombo(type: CardType.bomb, cards: cards, mainValue: sortedKeys.first, length: 1);
    }

    // 单张
    if (cards.length == 1) {
      return CardCombo(type: CardType.single, cards: cards, mainValue: sortedKeys.first, length: 1);
    }

    // 对子
    if (cards.length == 2 && counts.every((c) => c == 2)) {
      return CardCombo(type: CardType.pair, cards: cards, mainValue: sortedKeys.first, length: 1);
    }

    // 三张
    if (cards.length == 3 && counts.every((c) => c == 3)) {
      return CardCombo(type: CardType.triple, cards: cards, mainValue: sortedKeys.first, length: 1);
    }

    // 三带一
    if (cards.length == 4) {
      final tripleKey = sortedKeys.firstWhere((k) => groups[k]!.length == 3, orElse: () => -1);
      if (tripleKey != -1) {
        return CardCombo(type: CardType.tripleWithSingle, cards: cards, mainValue: tripleKey, length: 1);
      }
    }

    // 三带二
    if (cards.length == 5) {
      final tripleKey = sortedKeys.firstWhere((k) => groups[k]!.length == 3, orElse: () => -1);
      final pairKey = sortedKeys.firstWhere((k) => groups[k]!.length == 2, orElse: () => -1);
      if (tripleKey != -1 && pairKey != -1) {
        return CardCombo(type: CardType.tripleWithPair, cards: cards, mainValue: tripleKey, length: 1);
      }
    }

    // 顺子 (5+ 连续单张，不含2和王)
    if (counts.every((c) => c == 1) && cards.length >= 5) {
      if (sortedKeys.every((k) => k <= CardRank.ace.value)) {
        bool consecutive = true;
        for (int i = 1; i < sortedKeys.length; i++) {
          if (sortedKeys[i] != sortedKeys[i-1] + 1) { consecutive = false; break; }
        }
        if (consecutive) {
          return CardCombo(type: CardType.straight, cards: cards, mainValue: sortedKeys.first, length: cards.length);
        }
      }
    }

    // 连对 (3+ 连续对子，不含2和王)
    if (counts.every((c) => c == 2) && cards.length >= 6) {
      if (sortedKeys.every((k) => k <= CardRank.ace.value)) {
        bool consecutive = true;
        for (int i = 1; i < sortedKeys.length; i++) {
          if (sortedKeys[i] != sortedKeys[i-1] + 1) { consecutive = false; break; }
        }
        if (consecutive) {
          return CardCombo(type: CardType.consecutivePairs, cards: cards, mainValue: sortedKeys.first, length: sortedKeys.length);
        }
      }
    }

    // 飞机/飞机带翅膀
    final tripleKeys = sortedKeys.where((k) => groups[k]!.length >= 3).toList();
    if (tripleKeys.length >= 2) {
      // 找连续的三张
      tripleKeys.sort();
      final consecutiveTriples = <List<int>>[];
      var current = <int>[tripleKeys.first];
      for (int i = 1; i < tripleKeys.length; i++) {
        if (tripleKeys[i] == tripleKeys[i-1] + 1 && tripleKeys[i] <= CardRank.ace.value) {
          current.add(tripleKeys[i]);
        } else {
          if (current.length >= 2) consecutiveTriples.add(List.from(current));
          current = [tripleKeys[i]];
        }
      }
      if (current.length >= 2) consecutiveTriples.add(List.from(current));

      for (final seq in consecutiveTriples) {
        final n = seq.length;
        // 纯飞机
        if (cards.length == n * 3) {
          return CardCombo(type: CardType.airplane, cards: cards, mainValue: seq.first, length: n);
        }
        // 飞机带单张
        if (cards.length == n * 4) {
          return CardCombo(type: CardType.airplaneWithSingles, cards: cards, mainValue: seq.first, length: n);
        }
        // 飞机带对子
        if (cards.length == n * 5) {
          return CardCombo(type: CardType.airplaneWithPairs, cards: cards, mainValue: seq.first, length: n);
        }
      }
    }

    // 四带二
    if (cards.length == 6) {
      final fourKey = sortedKeys.firstWhere((k) => groups[k]!.length == 4, orElse: () => -1);
      if (fourKey != -1) {
        return CardCombo(type: CardType.fourWithTwoSingles, cards: cards, mainValue: fourKey, length: 1);
      }
    }

    // 四带两对
    if (cards.length == 8) {
      final fourKey = sortedKeys.firstWhere((k) => groups[k]!.length == 4, orElse: () => -1);
      final pairCount = sortedKeys.where((k) => groups[k]!.length == 2).length;
      if (fourKey != -1 && pairCount == 2) {
        return CardCombo(type: CardType.fourWithTwoPairs, cards: cards, mainValue: fourKey, length: 1);
      }
    }

    return const CardCombo(type: CardType.invalid, cards: [], mainValue: 0, length: 0);
  }

  static bool canBeat(CardCombo? newCombo, CardCombo? lastCombo) {
    if (newCombo == null || newCombo.type == CardType.invalid) return false;
    if (lastCombo == null) return true;

    // 王炸最大
    if (newCombo.type == CardType.rocket) return true;
    if (lastCombo.type == CardType.rocket) return false;

    // 炸弹
    if (newCombo.type == CardType.bomb && lastCombo.type != CardType.bomb) return true;
    if (lastCombo.type == CardType.bomb && newCombo.type != CardType.bomb) return false;

    // 同类型比较
    if (newCombo.type != lastCombo.type) return false;
    if (newCombo.length != lastCombo.length) return false;
    return newCombo.mainValue > lastCombo.mainValue;
  }
}
