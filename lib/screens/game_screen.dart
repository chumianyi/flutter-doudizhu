import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_state.dart';
import '../models/card.dart';
import '../models/player.dart';
import '../services/storage_service.dart';
import '../widgets/playing_card.dart';

class GameScreen extends StatefulWidget {
  final GameState gameState;
  final bool showDownloadButton;

  const GameScreen({
    super.key,
    required this.gameState,
    this.showDownloadButton = false,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final Set<String> _selectedCardIds = {};
  int _happyBeans = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    widget.gameState.addListener(_onGameChange);
    _loadBeans();
  }

  @override
  void dispose() {
    widget.gameState.removeListener(_onGameChange);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _loadBeans() {
    setState(() {
      _happyBeans = StorageService.getHappyBeans();
    });
  }

  void _onGameChange() {
    _loadBeans();
    setState(() {});
  }

  void _toggleCard(PlayingCard card) {
    setState(() {
      if (_selectedCardIds.contains(card.id)) {
        _selectedCardIds.remove(card.id);
      } else {
        _selectedCardIds.add(card.id);
      }
    });
  }

  List<PlayingCard> _getSelectedCards() {
    return widget.gameState.humanPlayer.hand
        .where((c) => _selectedCardIds.contains(c.id))
        .toList();
  }

  void _playSelected() {
    final cards = _getSelectedCards();
    if (cards.isEmpty) return;
    widget.gameState.playCards(cards);
    _selectedCardIds.clear();
  }

  @override
  Widget build(BuildContext context) {
    final gs = widget.gameState;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 顶部信息栏
              Positioned(
                top: 8,
                left: 16,
                right: 16,
                child: _buildTopBar(context),
              ),
              // 左侧玩家
              Positioned(
                left: 16,
                top: 70,
                bottom: 180,
                child: _buildSidePlayer(context, gs.players[1], true),
              ),
              // 右侧玩家
              Positioned(
                right: 16,
                top: 70,
                bottom: 180,
                child: _buildSidePlayer(context, gs.players[2], false),
              ),
              // 中央出牌区
              Positioned(
                left: 120,
                right: 120,
                top: 80,
                bottom: 200,
                child: _buildCenterArea(context),
              ),
              // 底部玩家手牌
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomPlayer(context),
              ),
              // 消息提示
              if (gs.message.isNotEmpty)
                Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      child: Text(
                        gs.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final gs = widget.gameState;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.sentiment_very_satisfied,
                      size: 18, color: Theme.of(context).colorScheme.onSecondaryContainer),
                  const SizedBox(width: 4),
                  Text(
                    '$_happyBeans',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '快乐豆',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (gs.phase == GamePhase.playing && gs.landlordIndex >= 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '底注 ${gs.bet}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                ),
              ),
          ],
        ),
        Row(
          children: [
            if (widget.showDownloadButton)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton.tonalIcon(
                  onPressed: _downloadWeb,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('下载网页'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            IconButton(
              icon: Icon(gs.soundEnabled ? Icons.volume_up : Icons.volume_off),
              onPressed: gs.toggleSound,
              tooltip: gs.soundEnabled ? '关闭语音' : '开启语音',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _selectedCardIds.clear();
                gs.startNewGame();
              },
              tooltip: '重新开始',
            ),
          ],
        ),
      ],
    );
  }

  void _downloadWeb() {
    // 通过 JS 触发下载
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('下载网页版'),
        content: const Text('网页版已准备好下载。点击确认后将下载完整的网页压缩包。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('正在准备下载...')),
              );
            },
            child: const Text('确认下载'),
          ),
        ],
      ),
    );
  }

  Widget _buildSidePlayer(BuildContext context, Player player, bool isLeft) {
    final gs = widget.gameState;
    final isCurrent = gs.players.indexOf(player) == gs.currentPlayerIndex &&
        (gs.phase == GamePhase.playing || gs.phase == GamePhase.calling);
    final isLandlord = player.role == PlayerRole.landlord;

    return SizedBox(
      width: 90,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCurrent
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrent
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isLandlord
                      ? Theme.of(context).colorScheme.tertiary
                      : Theme.of(context).colorScheme.secondary,
                  child: Text(
                    player.name.substring(0, 1),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  player.name,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                if (isLandlord)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '地主',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.style, size: 14, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 2),
                    Text(
                      '${player.cardCount}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 显示该玩家刚出的牌
          if (gs.lastPlayerIndex == gs.players.indexOf(player) && gs.lastPlayedCards != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildMiniCards(gs.lastPlayedCards!),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniCards(List<PlayingCard> cards) {
    final displayCards = cards.length > 6 ? cards.sublist(0, 6) : cards;
    return Wrap(
      spacing: -20,
      children: displayCards.map((c) =>
        PlayingCardWidget(
          card: c,
          width: 36,
          height: 52,
        ),
      ).toList(),
    );
  }

  Widget _buildCenterArea(BuildContext context) {
    final gs = widget.gameState;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 底牌显示
        if (gs.phase == GamePhase.calling || gs.phase == GamePhase.playing)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('底牌：', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              ...gs.bottomCards.map((c) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: PlayingCardWidget(
                  card: c,
                  width: 40,
                  height: 58,
                  faceDown: gs.landlordIndex < 0,
                ),
              )),
            ],
          ),
        const SizedBox(height: 20),
        // 叫地主阶段
        if (gs.phase == GamePhase.calling && gs.currentPlayerIndex == 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: () => gs.callLandlord(true),
                child: const Text('叫地主'),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () => gs.callLandlord(false),
                child: const Text('不叫'),
              ),
            ],
          ),
        // 游戏结束
        if (gs.phase == GamePhase.ended)
          Column(
            children: [
              Text(
                gs.message,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  _selectedCardIds.clear();
                  gs.startNewGame();
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('再来一局'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildBottomPlayer(BuildContext context) {
    final gs = widget.gameState;
    final player = gs.humanPlayer;
    final isCurrent = gs.currentPlayerIndex == 0 && gs.phase == GamePhase.playing;
    final isLandlord = player.role == PlayerRole.landlord;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 玩家信息和操作按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isLandlord
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.secondary,
                    child: Text(
                      '我',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '你',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (isLandlord)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '地主',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    '${player.cardCount}张',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  if (isCurrent)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '你的回合',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // 操作按钮
              if (gs.phase == GamePhase.playing && isCurrent)
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: (gs.lastCombo != null && gs.lastPlayerIndex != 0)
                          ? () {
                              gs.pass();
                              _selectedCardIds.clear();
                            }
                          : null,
                      child: const Text('不要'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _getSelectedCards().isNotEmpty ? _playSelected : null,
                      child: const Text('出牌'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          // 手牌
          SizedBox(
            height: 100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: player.hand.map((card) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: PlayingCardWidget(
                      card: card,
                      selected: _selectedCardIds.contains(card.id),
                      width: 50,
                      height: 72,
                      onTap: isCurrent ? () => _toggleCard(card) : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
