import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/player_avatar.dart';
import '../data/game_repository.dart';
import '../data/models.dart';
import 'create_game_screen.dart';
import 'game_screen.dart';
import 'join_game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.userId});
  final String userId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = GameRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeader(context),
          _buildActionCards(context),
          _buildGamesSection(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: AppTheme.headerDecoration,
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🃏', style: TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rummy Score Keeper',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Keep score. Play more.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _HeaderButton(
                    icon: Icons.add,
                    label: '+ Create Game',
                    onTap: () => _goCreate(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HeaderButton(
                    icon: Icons.login,
                    label: 'Join with Code',
                    onTap: () => _goJoin(context),
                    outlined: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCards(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Row(
          children: [
            Expanded(
              child: _QuickCard(
                icon: Icons.login_rounded,
                title: 'Join with Code',
                subtitle: 'Enter a game code to join',
                onTap: () => _goJoin(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickCard(
                icon: Icons.history_rounded,
                title: 'Game History',
                subtitle: 'View your past games',
                onTap: null, // scrolls down — handled naturally
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamesSection(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Games',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Game>>(
              stream: _repo.watchMyGames(widget.userId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final games = snap.data ?? [];
                if (games.isEmpty) {
                  return _EmptyState(onCreate: () => _goCreate(context));
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: games.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _GameCard(
                    game: games[i],
                    repo: _repo,
                    onTap: () => _openGame(context, games[i]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _goCreate(BuildContext context) async {
    final game = await Navigator.push<Game>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateGameScreen(userId: widget.userId, repo: _repo),
      ),
    );
    if (game != null && context.mounted) {
      _openGame(context, game);
    }
  }

  void _goJoin(BuildContext context) async {
    final game = await Navigator.push<Game>(
      context,
      MaterialPageRoute(
        builder: (_) => JoinGameScreen(userId: widget.userId, repo: _repo),
      ),
    );
    if (game != null && context.mounted) {
      _openGame(context, game);
    }
  }

  void _openGame(BuildContext context, Game game) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          gameId: game.id,
          userId: widget.userId,
          repo: _repo,
        ),
      ),
    );
  }
}

// ── Header action button ──────────────────────────────────────────────────────

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.outlined = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: outlined
              ? Colors.transparent
              : Colors.white,
          border: outlined
              ? Border.all(color: Colors.white, width: 1.5)
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: outlined ? Colors.white : const Color(0xFF1565C0)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: outlined ? Colors.white : const Color(0xFF1565C0),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick card ────────────────────────────────────────────────────────────────

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1ECF8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF1565C0), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Color(0xFF5A6080), fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF5A6080), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Game card ─────────────────────────────────────────────────────────────────

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.game,
    required this.repo,
    required this.onTap,
  });
  final Game game;
  final GameRepository repo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCompleted = game.isCompleted;
    final statusColor =
        isCompleted ? const Color(0xFF2E7D32) : const Color(0xFF1565C0);
    final statusBg =
        isCompleted ? const Color(0xFFE4F1E4) : const Color(0xFFE1ECF8);
    final statusLabel = isCompleted ? 'Completed' : 'In Progress';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE1ECF8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🃏', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      game.code,
                      style: const TextStyle(
                          color: Color(0xFF5A6080),
                          fontSize: 12,
                          fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildPlayers(game.id),
                        const SizedBox(width: 8),
                        Text(
                          'Round ${game.currentRound} / ${game.totalRounds}',
                          style: const TextStyle(
                              color: Color(0xFF5A6080), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Color(0xFFC62828), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayers(String gameId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('games')
          .doc(gameId)
          .collection('players')
          .snapshots(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        final players = snap.data?.docs ?? [];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: (players.take(4).length * 18.0) + 4,
              height: 24,
              child: Stack(
                children: [
                  for (var i = 0; i < players.take(4).length; i++)
                    Positioned(
                      left: i * 18.0,
                      child: PlayerAvatar(
                        name: (players[i].data()
                                as Map<String, dynamic>)['name'] as String? ??
                            '?',
                        index: i,
                        radius: 12,
                        fontSize: 9,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Text('$count',
                style: const TextStyle(
                    color: Color(0xFF5A6080), fontSize: 12)),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this game?'),
        content: const Text('This will remove the saved scorecard.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await repo.deleteGame(game.id);
            },
            child: const Text('DELETE',
                style: TextStyle(color: Color(0xFFC62828))),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Text('🃏', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'No games yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a game to start keeping score.',
              style: TextStyle(color: Color(0xFF5A6080)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: onCreate,
                child: const Text('+ Create Game'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
