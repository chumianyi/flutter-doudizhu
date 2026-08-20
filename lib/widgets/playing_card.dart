import 'package:flutter/material.dart';
import '../models/card.dart';

class PlayingCardWidget extends StatelessWidget {
  final PlayingCard card;
  final bool selected;
  final bool faceDown;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const PlayingCardWidget({
    super.key,
    required this.card,
    this.selected = false,
    this.faceDown = false,
    this.width = 56,
    this.height = 80,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (faceDown) {
      return _buildFaceDown(context);
    }

    final isRed = card.isRed;
    final color = isRed ? Colors.red : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        width: width,
        height: height,
        margin: EdgeInsets.only(bottom: selected ? 16 : 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: _buildCardContent(color),
      ),
    );
  }

  Widget _buildCardContent(Color color) {
    if (card.rank == CardRank.smallJoker || card.rank == CardRank.bigJoker) {
      final isBig = card.rank == CardRank.bigJoker;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isBig ? '大王' : '小王',
            style: TextStyle(
              color: isBig ? Colors.red : Colors.black,
              fontSize: width * 0.22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Icon(
            isBig ? Icons.style : Icons.whatshot,
            color: isBig ? Colors.red : Colors.black,
            size: width * 0.3,
          ),
        ],
      );
    }

    final suitChar = {
      CardSuit.spade: '♠',
      CardSuit.heart: '♥',
      CardSuit.club: '♣',
      CardSuit.diamond: '♦',
    }[card.suit]!;

    final rankChar = {
      CardRank.three: '3', CardRank.four: '4', CardRank.five: '5',
      CardRank.six: '6', CardRank.seven: '7', CardRank.eight: '8',
      CardRank.nine: '9', CardRank.ten: '10', CardRank.jack: 'J',
      CardRank.queen: 'Q', CardRank.king: 'K', CardRank.ace: 'A',
      CardRank.two: '2',
    }[card.rank]!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4),
          child: Align(
            alignment: Alignment.topLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rankChar,
                  style: TextStyle(
                    color: color,
                    fontSize: width * 0.26,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                Text(
                  suitChar,
                  style: TextStyle(
                    color: color,
                    fontSize: width * 0.24,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        Text(
          suitChar,
          style: TextStyle(
            color: color,
            fontSize: width * 0.4,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4, right: 4),
          child: Align(
            alignment: Alignment.bottomRight,
            child: Transform.rotate(
              angle: 3.14159,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rankChar,
                    style: TextStyle(
                      color: color,
                      fontSize: width * 0.26,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  Text(
                    suitChar,
                    style: TextStyle(
                      color: color,
                      fontSize: width * 0.24,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFaceDown(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.style,
          color: Colors.white.withValues(alpha: 0.6),
          size: width * 0.4,
        ),
      ),
    );
  }
}
