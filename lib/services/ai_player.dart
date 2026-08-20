import '../models/card.dart';
import '../models/player.dart';
import 'game_logic.dart';

class AiPlayer {
  static List<PlayingCard> chooseCards(Player player, CardCombo? lastCombo, bool isLandlordTurn) {
    final hand = List<PlayingCard>.from(player.hand)..sort((a, b) => a.rank.value.compareTo(b.rank.value));

    if (lastCombo == null) {
      return _chooseLeadingCards(hand);
    }

    // 尝试按同类型压牌
    final result = _tryBeat(hand, lastCombo);
    if (result != null) return result;

    // 尝试炸弹
    final bomb = _findBomb(hand, lastCombo);
    if (bomb != null) return bomb;

    // 尝试王炸
    if (hand.any((c) => c.rank == CardRank.smallJoker) &&
        hand.any((c) => c.rank == CardRank.bigJoker) &&
        lastCombo.type != CardType.rocket) {
      return [
        hand.firstWhere((c) => c.rank == CardRank.smallJoker),
        hand.firstWhere((c) => c.rank == CardRank.bigJoker),
      ];
    }

    return []; // 不要
  }

  static List<PlayingCard> _chooseLeadingCards(List<PlayingCard> hand) {
    // 优先出小牌型
    final groups = <int, List<PlayingCard>>{};
    for (final c in hand) {
      groups.putIfAbsent(c.rank.value, () => []).add(c);
    }

    // 找最小的单张（非王非2）
    final singles = groups.entries.where((e) => e.value.length == 1 && e.key < CardRank.two.value).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (singles.isNotEmpty) return [singles.first.value.first];

    // 找最小的对子
    final pairs = groups.entries.where((e) => e.value.length >= 2 && e.key < CardRank.two.value).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (pairs.isNotEmpty) return pairs.first.value.take(2).toList();

    // 最小三张
    final triples = groups.entries.where((e) => e.value.length >= 3 && e.key < CardRank.two.value).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (triples.isNotEmpty) {
      final triple = triples.first.value.take(3).toList();
      // 带一张最小单牌
      final otherSingle = hand.where((c) => !triple.contains(c) && c.rank.value < CardRank.two.value).toList()
        ..sort((a, b) => a.rank.value.compareTo(b.rank.value));
      if (otherSingle.isNotEmpty) triple.add(otherSingle.first);
      return triple;
    }

    // 出最小的单张
    final sorted = List<PlayingCard>.from(hand)..sort((a, b) => a.rank.value.compareTo(b.rank.value));
    return [sorted.first];
  }

  static List<PlayingCard>? _tryBeat(List<PlayingCard> hand, CardCombo last) {
    final groups = <int, List<PlayingCard>>{};
    for (final c in hand) {
      groups.putIfAbsent(c.rank.value, () => []).add(c);
    }
    final sortedKeys = groups.keys.toList()..sort();

    switch (last.type) {
      case CardType.single:
        for (final k in sortedKeys) {
          if (k > last.mainValue && groups[k]!.isNotEmpty) return [groups[k]!.first];
        }
        return null;

      case CardType.pair:
        for (final k in sortedKeys) {
          if (k > last.mainValue && groups[k]!.length >= 2) return groups[k]!.take(2).toList();
        }
        return null;

      case CardType.triple:
        for (final k in sortedKeys) {
          if (k > last.mainValue && groups[k]!.length >= 3) return groups[k]!.take(3).toList();
        }
        return null;

      case CardType.tripleWithSingle:
        for (final k in sortedKeys) {
          if (k > last.mainValue && groups[k]!.length >= 3) {
            final triple = groups[k]!.take(3).toList();
            final others = hand.where((c) => !triple.contains(c)).toList()
              ..sort((a, b) => a.rank.value.compareTo(b.rank.value));
            if (others.isNotEmpty) {
              triple.add(others.first);
              return triple;
            }
          }
        }
        return null;

      case CardType.tripleWithPair:
        for (final k in sortedKeys) {
          if (k > last.mainValue && groups[k]!.length >= 3) {
            final triple = groups[k]!.take(3).toList();
            for (final pk in sortedKeys) {
              if (pk != k && groups[pk]!.length >= 2) {
                triple.addAll(groups[pk]!.take(2));
                return triple;
              }
            }
          }
        }
        return null;

      case CardType.straight:
        final len = last.length;
        for (int start = last.mainValue + 1; start <= CardRank.ace.value - len + 1; start++) {
          bool ok = true;
          for (int i = 0; i < len; i++) {
            if (!groups.containsKey(start + i) || groups[start + i]!.isEmpty) { ok = false; break; }
          }
          if (ok) {
            return List.generate(len, (i) => groups[start + i]!.first);
          }
        }
        return null;

      case CardType.consecutivePairs:
        final len = last.length;
        for (int start = last.mainValue + 1; start <= CardRank.ace.value - len + 1; start++) {
          bool ok = true;
          for (int i = 0; i < len; i++) {
            if (!groups.containsKey(start + i) || groups[start + i]!.length < 2) { ok = false; break; }
          }
          if (ok) {
            final result = <PlayingCard>[];
            for (int i = 0; i < len; i++) result.addAll(groups[start + i]!.take(2));
            return result;
          }
        }
        return null;

      default:
        return null;
    }
  }

  static List<PlayingCard>? _findBomb(List<PlayingCard> hand, CardCombo last) {
    if (last.type == CardType.bomb || last.type == CardType.rocket) return null;
    final groups = <int, List<PlayingCard>>{};
    for (final c in hand) {
      groups.putIfAbsent(c.rank.value, () => []).add(c);
    }
    for (final entry in groups.entries) {
      if (entry.value.length == 4) return entry.value;
    }
    return null;
  }

  static bool shouldCallLandlord(Player player) {
    int score = 0;
    for (final c in player.hand) {
      if (c.rank == CardRank.bigJoker) score += 4;
      else if (c.rank == CardRank.smallJoker) score += 3;
      else if (c.rank == CardRank.two) score += 2;
      else if (c.rank == CardRank.ace) score += 1;
    }
    // 炸弹加分
    final groups = <int, int>{};
    for (final c in player.hand) {
      groups[c.rank.value] = (groups[c.rank.value] ?? 0) + 1;
    }
    for (final count in groups.values) {
      if (count == 4) score += 4;
    }
    return score >= 8;
  }
}
