import 'package:flutter/foundation.dart';
import '../models/card.dart';
import '../models/player.dart';
import 'game_logic.dart';
import 'ai_player.dart';
import 'voice_service.dart';
import 'storage_service.dart';

enum GamePhase { dealing, calling, playing, ended }

class GameState extends ChangeNotifier {
  List<Player> players = [];
  List<PlayingCard> bottomCards = [];
  int currentPlayerIndex = 0;
  int landlordIndex = -1;
  GamePhase phase = GamePhase.dealing;
  List<PlayingCard>? lastPlayedCards;
  CardCombo? lastCombo;
  int lastPlayerIndex = -1;
  int passCount = 0;
  String message = '';
  int bet = 100;
  bool soundEnabled = true;

  Player get humanPlayer => players.firstWhere((p) => p.isHuman);
  Player? get currentPlayer => currentPlayerIndex < players.length ? players[currentPlayerIndex] : null;

  Future<void> initGame() async {
    soundEnabled = StorageService.getSoundEnabled();
    VoiceService.setEnabled(soundEnabled);
    await startNewGame();
  }

  Future<void> startNewGame() async {
    final deck = shuffleDeck(createDeck());
    players = [
      Player(name: '你', position: PlayerPosition.bottom, isHuman: true),
      Player(name: '左家', position: PlayerPosition.left, isHuman: false),
      Player(name: '右家', position: PlayerPosition.right, isHuman: false),
    ];

    for (int i = 0; i < 51; i++) {
      players[i % 3].hand.add(deck[i]);
    }
    bottomCards = deck.sublist(51, 54);

    for (final p in players) {
      p.sortHand();
    }

    landlordIndex = -1;
    currentPlayerIndex = 0;
    phase = GamePhase.calling;
    lastPlayedCards = null;
    lastCombo = null;
    lastPlayerIndex = -1;
    passCount = 0;
    message = '叫地主阶段';
    notifyListeners();
  }

  void callLandlord(bool call) {
    if (phase != GamePhase.calling) return;
    if (call) {
      landlordIndex = currentPlayerIndex;
      players[currentPlayerIndex].role = PlayerRole.landlord;
      players[currentPlayerIndex].hand.addAll(bottomCards);
      players[currentPlayerIndex].sortHand();
      for (int i = 0; i < 3; i++) {
        if (i != landlordIndex) players[i].role = PlayerRole.farmer;
      }
      phase = GamePhase.playing;
      currentPlayerIndex = landlordIndex;
      lastPlayedCards = null;
      lastCombo = null;
      lastPlayerIndex = -1;
      passCount = 0;
      message = '${players[landlordIndex].name} 是地主';
      if (players[landlordIndex].isHuman) {
        VoiceService.playLandlord();
      }
      notifyListeners();
      if (!players[currentPlayerIndex].isHuman) {
        Future.delayed(const Duration(milliseconds: 1200), _aiTurn);
      }
    } else {
      _nextCallTurn();
    }
  }

  void _nextCallTurn() {
    currentPlayerIndex = (currentPlayerIndex + 1) % 3;
    if (currentPlayerIndex == 0) {
      // 没人叫地主，重新发牌
      message = '无人叫地主，重新发牌';
      notifyListeners();
      Future.delayed(const Duration(seconds: 1), startNewGame);
      return;
    }
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 800), _aiCall);
  }

  void _aiCall() {
    if (phase != GamePhase.calling) return;
    final player = players[currentPlayerIndex];
    final call = AiPlayer.shouldCallLandlord(player);
    callLandlord(call);
  }

  void playCards(List<PlayingCard> cards) {
    if (phase != GamePhase.playing) return;
    if (currentPlayerIndex != 0) return; // 不是人类回合

    final combo = GameLogic.analyzeCards(cards);
    if (combo == null || combo.type == CardType.invalid) {
      message = '牌型不正确';
      notifyListeners();
      return;
    }

    if (lastCombo != null && lastPlayerIndex != 0) {
      if (!GameLogic.canBeat(combo, lastCombo)) {
        message = '压不上上家的牌';
        notifyListeners();
        return;
      }
    }

    _executePlay(0, cards, combo);
  }

  void pass() {
    if (phase != GamePhase.playing) return;
    if (currentPlayerIndex != 0) return;
    if (lastCombo == null || lastPlayerIndex == 0) {
      message = '你是首出，不能不要';
      notifyListeners();
      return;
    }
    _executePass(0);
  }

  void _executePlay(int playerIndex, List<PlayingCard> cards, CardCombo combo) {
    final player = players[playerIndex];
    player.removeCards(cards);
    lastPlayedCards = cards;
    lastCombo = combo;
    lastPlayerIndex = playerIndex;
    passCount = 0;
    message = '${player.name} 出牌';

    if (player.isHuman) {
      VoiceService.speak(cards.map((c) => c.display).join(' '));
    } else {
      VoiceService.speak(cards.map((c) => c.display).join(' '));
    }

    notifyListeners();

    if (player.hand.isEmpty) {
      _endGame(playerIndex);
      return;
    }

    currentPlayerIndex = (playerIndex + 1) % 3;
    notifyListeners();

    if (!players[currentPlayerIndex].isHuman) {
      Future.delayed(const Duration(milliseconds: 1000), _aiTurn);
    }
  }

  void _executePass(int playerIndex) {
    passCount++;
    message = '${players[playerIndex].name} 不要';
    if (players[playerIndex].isHuman) {
      VoiceService.playPass();
    } else {
      VoiceService.playPass();
    }

    if (passCount >= 2) {
      lastCombo = null;
      lastPlayedCards = null;
      lastPlayerIndex = -1;
      passCount = 0;
    }

    currentPlayerIndex = (playerIndex + 1) % 3;
    notifyListeners();

    if (!players[currentPlayerIndex].isHuman) {
      Future.delayed(const Duration(milliseconds: 800), _aiTurn);
    }
  }

  void _aiTurn() {
    if (phase != GamePhase.playing) return;
    final player = players[currentPlayerIndex];
    if (player.isHuman) return;

    final isLeader = lastCombo == null || lastPlayerIndex == currentPlayerIndex;
    final cards = AiPlayer.chooseCards(player, lastCombo, isLeader);

    if (cards.isEmpty) {
      if (isLeader) {
        // 首出必须出牌
        final forced = AiPlayer.chooseCards(player, null, true);
        if (forced.isNotEmpty) {
          final combo = GameLogic.analyzeCards(forced);
          if (combo != null) _executePlay(currentPlayerIndex, forced, combo);
          return;
        }
      }
      _executePass(currentPlayerIndex);
    } else {
      final combo = GameLogic.analyzeCards(cards);
      if (combo != null) {
        _executePlay(currentPlayerIndex, cards, combo);
      } else {
        _executePass(currentPlayerIndex);
      }
    }
  }

  void _endGame(int winnerIndex) {
    phase = GamePhase.ended;
    final winner = players[winnerIndex];
    final landlordWon = winner.role == PlayerRole.landlord;

    int beansChange = 0;
    if (humanPlayer.role == PlayerRole.landlord) {
      beansChange = landlordWon ? bet * 2 : -bet * 2;
    } else {
      beansChange = landlordWon ? -bet : bet;
    }

    StorageService.addHappyBeans(beansChange);
    StorageService.incrementTotalGames();
    if (beansChange > 0) StorageService.incrementWinCount();

    if (landlordWon) {
      message = '地主获胜！${beansChange >= 0 ? '+' : ''}$beansChange 快乐豆';
      VoiceService.playLandlordWin();
    } else {
      message = '农民获胜！${beansChange >= 0 ? '+' : ''}$beansChange 快乐豆';
      VoiceService.playFarmerWin();
    }
    notifyListeners();
  }

  void toggleSound() {
    soundEnabled = !soundEnabled;
    StorageService.setSoundEnabled(soundEnabled);
    VoiceService.setEnabled(soundEnabled);
    notifyListeners();
  }
}
