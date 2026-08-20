import 'card.dart';

enum PlayerRole { landlord, farmer }
enum PlayerPosition { bottom, left, right }

class Player {
  final String name;
  final PlayerPosition position;
  List<PlayingCard> hand;
  PlayerRole role;
  bool isHuman;

  Player({
    required this.name,
    required this.position,
    List<PlayingCard>? hand,
    this.role = PlayerRole.farmer,
    this.isHuman = false,
  }) : hand = hand ?? [];

  int get cardCount => hand.length;

  void sortHand() {
    hand.sort((a, b) => b.rank.value.compareTo(a.rank.value));
  }

  void removeCards(List<PlayingCard> cards) {
    final ids = cards.map((c) => c.id).toSet();
    hand = hand.where((c) => !ids.contains(c.id)).toList();
  }
}
