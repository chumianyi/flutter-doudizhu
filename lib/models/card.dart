enum CardSuit { spade, heart, club, diamond, joker }

enum CardRank {
  three(3), four(4), five(5), six(6), seven(7), eight(8),
  nine(9), ten(10), jack(11), queen(12), king(13),
  ace(14), two(15), smallJoker(16), bigJoker(17);

  final int value;
  const CardRank(this.value);
}

class PlayingCard {
  final CardSuit suit;
  final CardRank rank;
  final String id;

  const PlayingCard({required this.suit, required this.rank, required this.id});

  String get display {
    if (rank == CardRank.smallJoker) return '小王';
    if (rank == CardRank.bigJoker) return '大王';
    final suitChar = {
      CardSuit.spade: '♠',
      CardSuit.heart: '♥',
      CardSuit.club: '♣',
      CardSuit.diamond: '♦',
    }[suit]!;
    final rankChar = {
      CardRank.three: '3', CardRank.four: '4', CardRank.five: '5',
      CardRank.six: '6', CardRank.seven: '7', CardRank.eight: '8',
      CardRank.nine: '9', CardRank.ten: '10', CardRank.jack: 'J',
      CardRank.queen: 'Q', CardRank.king: 'K', CardRank.ace: 'A',
      CardRank.two: '2',
    }[rank]!;
    return '$suitChar$rankChar';
  }

  bool get isRed => suit == CardSuit.heart || suit == CardSuit.diamond || rank == CardRank.bigJoker;

  @override
  bool operator ==(Object other) => other is PlayingCard && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

List<PlayingCard> createDeck() {
  final deck = <PlayingCard>[];
  const suits = [CardSuit.spade, CardSuit.heart, CardSuit.club, CardSuit.diamond];
  const ranks = [
    CardRank.three, CardRank.four, CardRank.five, CardRank.six,
    CardRank.seven, CardRank.eight, CardRank.nine, CardRank.ten,
    CardRank.jack, CardRank.queen, CardRank.king, CardRank.ace, CardRank.two,
  ];
  for (final suit in suits) {
    for (final rank in ranks) {
      deck.add(PlayingCard(suit: suit, rank: rank, id: '${suit.name}_${rank.name}'));
    }
  }
  deck.add(const PlayingCard(suit: CardSuit.joker, rank: CardRank.smallJoker, id: 'small_joker'));
  deck.add(const PlayingCard(suit: CardSuit.joker, rank: CardRank.bigJoker, id: 'big_joker'));
  return deck;
}

List<PlayingCard> shuffleDeck(List<PlayingCard> deck) {
  final shuffled = List<PlayingCard>.from(deck);
  shuffled.shuffle();
  return shuffled;
}
