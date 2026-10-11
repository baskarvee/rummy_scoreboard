import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/gradient_app_bar.dart';
import '../core/widgets/player_avatar.dart';
import '../data/game_repository.dart';
import '../data/models.dart';

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({
    super.key,
    required this.userId,
    required this.repo,
  });
  final String userId;
  final GameRepository repo;

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final _playerCtrl = TextEditingController();
  final _playerFocus = FocusNode();

  final List<String> _players = [];
  bool _busy = false;

  /// Auto-generated name: "Wednesday, 23 Sep Â· 11:45 AM"
  String get _gameName {
    final now = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = days[now.weekday - 1];
    final month = months[now.month - 1];
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour < 12 ? 'AM' : 'PM';
    return '$day, ${now.day} $month Â· $hour:$minute $ampm';
  }

  @override
  void dispose() {
    _playerCtrl.dispose();
    _playerFocus.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final name = _playerCtrl.text.trim();
    if (name.isEmpty) return;
    if (_players.length >= AppConstants.maxPlayers) {
      _showSnack('Maximum ${AppConstants.maxPlayers} players allowed.');
      return;
    }
    setState(() {
      _players.add(name);
      _playerCtrl.clear();
    });
    // Re-focus after the rebuild completes. On the first add the player list
    // appears above the field, changing the layout; requesting focus
    // synchronously then gets lost, so defer to the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playerFocus.requestFocus();
    });
  }

  void _removePlayer(int index) {
    setState(() => _players.removeAt(index));
  }

  Future<void> _createGame() async {
    if (_players.length < AppConstants.minPlayers) {
      _showSnack('Add at least ${AppConstants.minPlayers} players.');
      return;
    }
    setState(() => _busy = true);
    try {
      final game = await widget.repo.createGame(
        name: _gameName,
        totalRounds: AppConstants.defaultRounds,
        hostUserId: widget.userId,
        playerNames: _players,
      );
      // Skip code panel â€” go straight to scorecard
      if (mounted) Navigator.pop(context, game);
    } catch (e) {
      if (mounted) _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'New Game'),
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    final canCreate = _players.length >= AppConstants.minPlayers;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            children: [
              // Game name display (not editable â€” auto set)
              _GameNameBadge(name: _gameName),
              const SizedBox(height: 28),

              // Player list (grows as you add)
              if (_players.isNotEmpty) ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _players.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _PlayerRow(
                    name: _players[i],
                    index: i,
                    onDelete: () => _removePlayer(i),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Add player input
              _AddPlayerField(
                controller: _playerCtrl,
                focusNode: _playerFocus,
                onAdd: _addPlayer,
                playerCount: _players.length,
              ),
            ],
          ),
        ),

        // Bottom action bar
        _BottomBar(
          canCreate: canCreate,
          busy: _busy,
          onTap: _createGame,
          playerCount: _players.length,
        ),
      ],
    );
  }

}

// â”€â”€ Game name badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _GameNameBadge extends StatelessWidget {
  const _GameNameBadge({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ðŸƒ  Rummy Game',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Player row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.name,
    required this.index,
    required this.onDelete,
  });
  final String name;
  final int index;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.avatarColor(index);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE3F0)),
      ),
      child: Row(
        children: [
          PlayerAvatar(name: name, index: index, radius: 18, fontSize: 13),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 18, color: color.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Add player field â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AddPlayerField extends StatelessWidget {
  const _AddPlayerField({
    required this.controller,
    required this.focusNode,
    required this.onAdd,
    required this.playerCount,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onAdd;
  final int playerCount;

  @override
  Widget build(BuildContext context) {
    final isFull = playerCount >= AppConstants.maxPlayers;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: !isFull,
            decoration: InputDecoration(
              hintText: isFull ? 'Max 10 players' : 'Add a player...',
              prefixIcon: const Icon(Icons.person_add_outlined, size: 20),
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onAdd(),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 48,
          height: 48,
          child: FilledButton(
            onPressed: isFull ? null : onAdd,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Icon(Icons.add, size: 22),
          ),
        ),
      ],
    );
  }
}

// â”€â”€ Bottom bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.canCreate,
    required this.busy,
    required this.onTap,
    required this.playerCount,
  });
  final bool canCreate;
  final bool busy;
  final VoidCallback onTap;
  final int playerCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (playerCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '$playerCount player${playerCount == 1 ? '' : 's'} Â· 10 rounds',
                style: const TextStyle(color: Color(0xFF5A6080), fontSize: 13),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (canCreate && !busy) ? onTap : null,
              child: busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      canCreate
                          ? 'Start Game'
                          : 'Add at least 2 players',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
