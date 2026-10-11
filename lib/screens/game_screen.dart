import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/gradient_app_bar.dart';
import '../core/widgets/player_avatar.dart';
import '../data/game_controller.dart';
import '../data/game_repository.dart';
import '../data/models.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// GameScreen
// ═══════════════════════════════════════════════════════════════════════════════

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.gameId, required this.userId, required this.repo});
  final String gameId;
  final String userId;
  final GameRepository repo;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = GameController(gameId: widget.gameId, repository: widget.repo); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  bool get _isHost => _ctrl.game?.hostUserId == widget.userId;
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (context, _) {
        final game = _ctrl.game;
        if (game == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (game.isCompleted) return _FinalResultsScreen(ctrl: _ctrl, onBack: () => Navigator.pop(context));
        return _ScoreboardScreen(ctrl: _ctrl, userId: widget.userId, isHost: _isHost);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Scoreboard Screen
// ═══════════════════════════════════════════════════════════════════════════════

class _ScoreboardScreen extends StatelessWidget {
  const _ScoreboardScreen({required this.ctrl, required this.userId, required this.isHost});
  final GameController ctrl;
  final String userId;
  final bool isHost;
  @override
  Widget build(BuildContext context) {
    final game = ctrl.game!;
    return Scaffold(
      appBar: GradientAppBar(title: game.name),
      body: Column(children: [
        _JoinCodeBanner(code: game.code),
        _RoundHeader(game: game, playerCount: ctrl.players.length),
        Expanded(child: _ScoreTable(ctrl: ctrl, userId: userId, isHost: isHost)),
        _EnterScoreBar(ctrl: ctrl, userId: userId, isHost: isHost),
      ]),
    );
  }
}

class _JoinCodeBanner extends StatelessWidget {
  const _JoinCodeBanner({required this.code});
  final String code;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE1ECF8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1565C0), width: 1.5),
        ),
        child: Row(children: [
          const Icon(Icons.vpn_key_rounded, color: Color(0xFF1565C0), size: 22),
          const SizedBox(width: 10),
          const Text('Join Code',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF5A6080))),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              code,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
                color: Color(0xFF0D47A1),
                fontFamily: 'monospace',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: Color(0xFF1565C0), size: 22),
            tooltip: 'Copy code',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied!')));
            },
          ),
        ]),
      ),
    );
  }
}

class _RoundHeader extends StatelessWidget {
  const _RoundHeader({required this.game, required this.playerCount});
  final Game game;
  final int playerCount;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        _StatChip(icon: Icons.people_outline, label: 'Players', value: '$playerCount/10'),
        const SizedBox(width: 8),
        _StatChip(icon: Icons.calendar_today_outlined, label: 'Round', value: '${game.currentRound}/${game.totalRounds}'),
        const SizedBox(width: 8),
        _StatChip(icon: Icons.timer_outlined, label: '',
          value: game.isInProgress ? 'In Progress' : 'Done',
          color: game.isInProgress ? const Color(0xFF1565C0) : const Color(0xFF2E7D32)),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, required this.value, this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF1565C0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        if (label.isNotEmpty) ...[
          Text(label, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w500)),
          const SizedBox(width: 2),
        ],
        Text(value, style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Score Table
// ═══════════════════════════════════════════════════════════════════════════════

class _ScoreTable extends StatelessWidget {
  const _ScoreTable({required this.ctrl, required this.userId, required this.isHost});
  final GameController ctrl;
  final String userId;
  final bool isHost;
  @override
  Widget build(BuildContext context) {
    final game = ctrl.game!;
    final players = ctrl.players;
    final totals = ctrl.totals;
    if (players.isEmpty) return const Center(child: CircularProgressIndicator());

    // Rank players 1..n by total (highest = rank 1). Ties share nothing fancy
    // — stable by player order. Only meaningful once scores exist.
    final anyScored = totals.values.any((v) => v != 0);
    final sortedByScore = [...players]
      ..sort((a, b) => (totals[b.id] ?? 0).compareTo(totals[a.id] ?? 0));
    final ranks = <String, int>{};
    for (var i = 0; i < sortedByScore.length; i++) {
      ranks[sortedByScore[i].id] = i + 1;
    }
    final allTotals = totals.values.toList();
    final maxTotal = allTotals.isEmpty ? 0 : allTotals.reduce((a, b) => a > b ? a : b);
    final minTotal = allTotals.isEmpty ? 0 : allTotals.reduce((a, b) => a < b ? a : b);

    const double rW = 48;              // round-label column width
    const double minPlayerW = 60;      // minimum per-player width
    const double hPad = 12;            // outer horizontal padding
    const double eW = editColW;        // trailing edit-icon column width

    return LayoutBuilder(builder: (context, constraints) {
      final available = constraints.maxWidth - rW - eW - (hPad * 2);
      final naturalPlayerW = available / players.length;
      final fits = naturalPlayerW >= minPlayerW;
      // Floor the per-player width so the summed cell widths never exceed the
      // table width (sub-pixel rounding was causing a RenderFlex overflow).
      final double pW = (fits ? naturalPlayerW : minPlayerW).floorToDouble();
      // When flexing, the table fills the available width exactly; otherwise it
      // is the sum of fixed columns (for horizontal scrolling).
      final tableWidth = fits
          ? (constraints.maxWidth - hPad * 2)
          : (rW + pW * players.length + eW);

      // When columns fit we let them flex to divide the row exactly (no pixel
      // drift). When they don't fit we fall back to fixed widths + h-scroll.
      final useFlex = fits;

      final table = Container(
        width: tableWidth,
        margin: const EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD6E0F0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // ── Header row (dark blue) — avatar, name, total pill with rank ──
          Container(
            color: const Color(0xFF0D47A1),
            child: Row(children: [
              _HeaderCell(width: rW, text: 'Round',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.white)),
              for (var i = 0; i < players.length; i++)
                _flex(useFlex, pW, _PlayerHeaderCell(
                  player: players[i], index: i, width: pW,
                  total: totals[players[i].id] ?? 0,
                  rank: anyScored ? ranks[players[i].id] : null,
                  minTotal: minTotal, maxTotal: maxTotal,
                )),
              _editSpacer(), // keep columns aligned with the edit column below
            ]),
          ),
          // ── Round rows ──
          for (var r = 1; r <= game.totalRounds; r++)
            _RoundRow(
              roundNumber: r, players: players, ctrl: ctrl,
              isCurrentRound: r == game.currentRound,
              userId: userId, isHost: isHost, roundColW: rW, playerColW: pW,
              useFlex: useFlex,
            ),
          // ── Rank row (BOTTOM) ──
          _rankRow(players, ranks, anyScored, rW, pW, useFlex),
        ]),
      );

      if (useFlex) {
        // Make table exactly fill available width so flex children divide evenly.
        return SingleChildScrollView(
          child: SizedBox(width: constraints.maxWidth, child: Center(child: table)),
        );
      }
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(child: table),
      );
    });
  }

  // Wrap a fixed-width cell in Expanded when flexing, else leave as-is.
  static Widget _flex(bool useFlex, double w, Widget child) =>
      useFlex ? Expanded(child: child) : child;

  // Fixed-width trailing column reserved for the per-row edit icon.
  static const double editColW = 36;
  static Widget _editSpacer() => const SizedBox(width: editColW, height: 40);

  // Builds the Rank row (bottom): medals for top 3, #n for the rest.
  static Widget _rankRow(List<Player> players, Map<String, int> ranks,
      bool anyScored, double rW, double pW, bool useFlex) {
    return Container(
      color: const Color(0xFFD2E0F5),
      child: Row(children: [
        _HeaderCell(width: rW, text: 'Rank',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0D47A1))),
        for (final p in players)
          _flex(useFlex, pW, _RankCell(rank: anyScored ? ranks[p.id] : null, width: pW)),
        _editSpacer(),
      ]),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.width, required this.text, this.style});
  final double width;
  final String text;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width, height: 40,
    child: Center(child: Text(text, style: style ??
        const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF5A6080)))),
  );
}

class _PlayerHeaderCell extends StatelessWidget {
  const _PlayerHeaderCell({
    required this.player, required this.index, required this.width,
    required this.total, required this.rank,
    required this.minTotal, required this.maxTotal,
  });
  final Player player;
  final int index;
  final double width;
  final int total;
  final int? rank;        // null until any score exists
  final int minTotal;
  final int maxTotal;

  // Shade from bright green (leader / highest) to bright red (lowest), based on
  // where this total sits in the current [minTotal..maxTotal] range. Uses
  // light/bright tones so the text stays readable on the dark-blue header.
  Color _pillColor() {
    const green = Color(0xFF69F0AE); // bright green
    const red = Color(0xFFFF8A80);   // bright red
    if (maxTotal == minTotal) return Colors.white; // all equal → white
    final t = (total - minTotal) / (maxTotal - minTotal); // 0 = worst, 1 = best
    return Color.lerp(red, green, t)!;
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _pillColor();
    return Container(
      width: width,
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player name
          Text(player.name.split(' ').first,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, height: 1.1),
            overflow: TextOverflow.ellipsis, maxLines: 1, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          // Colored total (green→red shaded)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(total > 0 ? '+$total' : '$total',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: scoreColor, height: 1.1)),
          ),
        ],
      ),
    );
  }
}

/// Compact "#n" rank badge shown next to the player's name. Top-3 get a
/// medal-tinted background; others a neutral translucent chip.
class _RankChip extends StatelessWidget {
  const _RankChip({required this.rank});
  final int rank;
  @override
  Widget build(BuildContext context) {
    final bg = rank == 1
        ? const Color(0xFFFFC107)      // gold
        : rank == 2
            ? const Color(0xFF90A4AE)  // silver
            : rank == 3
                ? const Color(0xFFA1887F) // bronze
                : Colors.white.withValues(alpha: 0.22);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('#$rank',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
    );
  }
}

/// Small orange notification badge showing a count (shared by avatar + cells).
class _ScootBadge extends StatelessWidget {
  const _ScootBadge({required this.count, required this.borderColor});
  final int count;
  final Color borderColor;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9800), // orange
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Center(
        child: Text('$count',
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}

class _RoundRow extends StatelessWidget {
  const _RoundRow({
    required this.roundNumber, required this.players, required this.ctrl,
    required this.isCurrentRound, required this.userId, required this.isHost,
    required this.roundColW, required this.playerColW, this.useFlex = false,
  });
  final int roundNumber;
  final List<Player> players;
  final GameController ctrl;
  final bool isCurrentRound;
  final String userId;
  final bool isHost;
  final double roundColW;
  final double playerColW;
  final bool useFlex;
  @override
  Widget build(BuildContext context) {
    final game = ctrl.game!;
    final round = ctrl.roundByNumber(roundNumber);
    final isPast = roundNumber < game.currentRound;
    final rowColor = isCurrentRound
        ? const Color(0xFFDCE8FB)
        : (roundNumber.isOdd ? Colors.white : const Color(0xFFEEF3FB));
    return Container(
      decoration: BoxDecoration(
        color: rowColor,
        border: isCurrentRound ? const Border(left: BorderSide(color: Color(0xFF1565C0), width: 3)) : null,
      ),
      child: Row(children: [
        SizedBox(width: roundColW, height: 44,
          child: Center(child: Text('$roundNumber',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
              color: isCurrentRound ? const Color(0xFF1565C0) : const Color(0xFF5A6080))))),
        for (final p in players)
          _ScoreTable._flex(useFlex, playerColW, _ScoreCell(
            player: p, round: round, isCurrentRound: isCurrentRound, width: playerColW,
            scootRunningCount: _scootsUpTo(p.id, roundNumber),
            onTap: isCurrentRound
                ? () => _openEntry(context, round, isEdit: false)
                : (isPast && (isHost || round?.winnerPlayerId == p.id))
                    ? () => _openEntry(context, round, isEdit: true)
                    : null,
          )),
        // Edit column — show an edit icon for the current round and any
        // played round the user is allowed to edit.
        SizedBox(
          width: _ScoreTable.editColW,
          height: 44,
          child: _canEdit(round, isPast)
              ? IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  icon: Icon(
                    isCurrentRound ? Icons.edit_note_rounded : Icons.edit_outlined,
                    color: const Color(0xFF1565C0),
                  ),
                  onPressed: () => _openEntry(context, round, isEdit: !isCurrentRound),
                )
              : const SizedBox.shrink(),
        ),
      ]),
    );
  }

  bool _canEdit(Round? round, bool isPast) {
    if (isCurrentRound) return true;              // always edit current round
    if (round == null) return false;              // future / empty round
    return isHost || round.winnerPlayerId == userId; // host or round winner
  }

  // Running number of scoots this player has had from round 1 up to [upTo].
  int _scootsUpTo(String playerId, int upTo) {
    var n = 0;
    for (var r = 1; r <= upTo; r++) {
      if (ctrl.roundByNumber(r)?.scores[playerId] == -20) n++;
    }
    return n;
  }

  void _openEntry(BuildContext context, Round? round, {required bool isEdit}) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ScoreEntryPage(
        players: players,
        existingRound: round,
        roundNumber: isEdit ? round!.roundNumber : ctrl.game!.currentRound,
        gameId: ctrl.game!.id, ctrl: ctrl, isEdit: isEdit,
      ),
    ));
  }
}

class _ScoreCell extends StatelessWidget {
  const _ScoreCell({
    required this.player, required this.round, required this.isCurrentRound,
    required this.width, this.onTap, this.scootRunningCount = 0,
  });
  final Player player;
  final Round? round;
  final bool isCurrentRound;
  final double width;
  final VoidCallback? onTap;
  /// Cumulative number of scoots this player has had up to & including this round.
  final int scootRunningCount;

  @override
  Widget build(BuildContext context) {
    final score = round?.scores[player.id];
    final isScoot = score == -20;

    Widget content;
    if (score == null) {
      content = const Text('-',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFBCC5D6)));
    } else if (isScoot) {
      // Plain red -20 number + running scoot-count badge (no pill)
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Text('-20',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.scoreNegative)),
          ),
          if (scootRunningCount > 0)
            Positioned(
              top: -8, right: -10,
              child: _ScootBadge(count: scootRunningCount, borderColor: Colors.white),
            ),
        ],
      );
    } else {
      final tc = score > 0 ? AppTheme.scorePositive : AppTheme.scoreNegative;
      content = Text(score > 0 ? '+$score' : '$score',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tc));
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width, height: 44,
        decoration: (isCurrentRound && score == null) ? BoxDecoration(
          border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(6),
          color: const Color(0xFFE8F0FE),
        ) : null,
        margin: isCurrentRound ? const EdgeInsets.all(2) : null,
        child: Center(child: content),
      ),
    );
  }
}

class _TotalCell extends StatelessWidget {
  const _TotalCell({required this.score, required this.width});
  final int score;
  final double width;
  @override
  Widget build(BuildContext context) {
    final color = score > 0 ? AppTheme.scorePositive : score < 0 ? AppTheme.scoreNegative : AppTheme.scoreNeutral;
    return SizedBox(width: width, height: 44,
      child: Center(child: Text(score > 0 ? '+$score' : '$score',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color))));
  }
}

/// Rank cell in the bottom row: 🏆 for #1, 🥇 for #2, 🥈 for #3, else "#n".
class _RankCell extends StatelessWidget {
  const _RankCell({required this.rank, required this.width});
  final int? rank;
  final double width;
  @override
  Widget build(BuildContext context) {
    if (rank == null) {
      return SizedBox(width: width, height: 44,
        child: const Center(child: Text('-',
          style: TextStyle(fontSize: 14, color: Color(0xFFBCC5D6)))));
    }
    // Champion cup, gold badge, silver certificate for 1/2/3.
    final String? icon = rank == 1 ? '🏆' : rank == 2 ? '🥇' : rank == 3 ? '🥈' : null;
    return SizedBox(
      width: width, height: 44,
      child: Center(
        child: icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 2),
                  Text('#$rank',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1))),
                ],
              )
            : Text('#$rank',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF5A6080))),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Enter Score Bar (bottom of scoreboard)
// ═══════════════════════════════════════════════════════════════════════════════

class _EnterScoreBar extends StatelessWidget {
  const _EnterScoreBar({required this.ctrl, required this.userId, required this.isHost});
  final GameController ctrl;
  final String userId;
  final bool isHost;
  @override
  Widget build(BuildContext context) {
    final game = ctrl.game!;
    final players = ctrl.players;
    final currentRound = ctrl.roundByNumber(game.currentRound);
    final allEntered = players.isNotEmpty && players.every((p) => currentRound?.scores[p.id] != null);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (allEntered && currentRound != null)
          _SubmitRoundButton(ctrl: ctrl, round: currentRound)
        else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: players.isEmpty ? null : () => _openFirst(context, players, currentRound),
              icon: const Icon(Icons.edit_outlined),
              label: Text('Enter Round ${game.currentRound} Score'),
            ),
          ),
          const SizedBox(height: 6),
          const Text('Tap a player\'s cell to enter their score for the current round.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFF5A6080))),
        ],
      ]),
    );
  }
  void _openFirst(BuildContext context, List<Player> players, Round? existing) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ScoreEntryPage(
        players: players, existingRound: existing,
        roundNumber: ctrl.game!.currentRound,
        gameId: ctrl.game!.id, ctrl: ctrl, isEdit: false,
      ),
    ));
  }
}

class _SubmitRoundButton extends StatefulWidget {
  const _SubmitRoundButton({required this.ctrl, required this.round});
  final GameController ctrl;
  final Round round;
  @override
  State<_SubmitRoundButton> createState() => _SubmitRoundButtonState();
}

class _SubmitRoundButtonState extends State<_SubmitRoundButton> {
  bool _busy = false;
  @override
  Widget build(BuildContext context) {
    final isValid = widget.round.total == 0;
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isValid ? const Color(0xFFE4F1E4) : const Color(0xFFFBE3E1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(isValid ? Icons.check_circle_outline : Icons.warning_amber_outlined,
            size: 16, color: isValid ? const Color(0xFF2E7D32) : const Color(0xFFC62828)),
          const SizedBox(width: 6),
          Text(isValid ? 'Round Total: 0 — Ready' : 'Round does not balance.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: isValid ? const Color(0xFF2E7D32) : const Color(0xFFC62828))),
        ]),
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (!isValid || _busy) ? null : () async {
            final messenger = ScaffoldMessenger.of(context);
            setState(() => _busy = true);
            final err = await widget.ctrl.submitRound(widget.round);
            if (!mounted) return;
            setState(() => _busy = false);
            if (err != null) messenger.showSnackBar(SnackBar(content: Text(err)));
          },
          child: _busy
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Submit Round ${widget.ctrl.game!.currentRound}'),
        ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Score Entry — Full Screen Page
// ═══════════════════════════════════════════════════════════════════════════════

class ScoreEntryPage extends StatefulWidget {
  const ScoreEntryPage({
    super.key,
    required this.players,
    required this.existingRound,
    required this.roundNumber,
    required this.gameId,
    required this.ctrl,
    required this.isEdit,
  });
  final List<Player> players;
  final Round? existingRound;
  final int roundNumber;
  final String gameId;
  final GameController ctrl;
  final bool isEdit;

  @override
  State<ScoreEntryPage> createState() => _ScoreEntryPageState();
}

class _ScoreEntryPageState extends State<ScoreEntryPage> {
  late Map<String, int?> _scores;
  String? _winnerId;
  // Players whose score was entered via the Custom dialog.
  final Set<String> _customPlayers = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _scores = {for (final p in widget.players) p.id: widget.existingRound?.scores[p.id]};
    _winnerId = (widget.existingRound?.winnerPlayerId.isNotEmpty == true)
        ? widget.existingRound!.winnerPlayerId
        : null;
    // Mark any existing non-quick negative score as a custom entry.
    for (final p in widget.players) {
      final ex = widget.existingRound?.scores[p.id];
      final isQuick = ex == AppConstants.scoreFull ||
          ex == AppConstants.scoreScoot ||
          ex == AppConstants.scoreQuit;
      if (ex != null && ex < 0 && !isQuick) _customPlayers.add(p.id);
    }
  }

  // ── Custom entry dialog ─────────────────────────────────────────────────────
  Future<void> _openCustomDialog(Player p) async {
    const red = Color(0xFFC62828);
    // Start from existing custom value, else default 20. Clamp 2..80.
    int value = _customPlayers.contains(p.id)
        ? (-(_scores[p.id] ?? 20)).clamp(2, 80)
        : 20;
    final ctrl = TextEditingController(text: '$value');

    final result = await showDialog<int>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialog) {
            void setValue(int v) {
              value = v.clamp(2, 80);
              ctrl.text = '$value';
              ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
              setDialog(() {});
            }

            Widget stepBtn(IconData icon, VoidCallback onTap) => Material(
              color: red.withValues(alpha: 0.1),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(icon, color: red, size: 24),
                ),
              ),
            );

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header: title + X close
                    Row(children: [
                      Expanded(
                        child: Text('${p.name} — Custom',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E))),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF5A6080)),
                        onPressed: () => Navigator.pop(dialogCtx), // close, no change
                      ),
                    ]),
                    const SizedBox(height: 4),
                    const Text('Points lost (2 to 80).',
                      style: TextStyle(fontSize: 13, color: Color(0xFF5A6080))),
                    const SizedBox(height: 18),
                    // − [ field ] +
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        stepBtn(Icons.remove_circle_outline, () => setValue(value - 1)),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 96,
                          child: TextField(
                            controller: ctrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'\d{0,2}')),
                            ],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: red),
                            decoration: InputDecoration(
                              prefixText: '−',
                              prefixStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: red),
                              hintText: '20',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onChanged: (t) {
                              final v = int.tryParse(t);
                              if (v != null) value = v; // committed on Save
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        stepBtn(Icons.add_circle_outline, () => setValue(value + 1)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          final v = (int.tryParse(ctrl.text.trim()) ?? value).clamp(2, 80);
                          Navigator.pop(dialogCtx, -v);
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    ctrl.dispose();
    if (result == null) return; // closed with X, no change
    setState(() {
      if (p.id == _winnerId) _winnerId = null;
      _customPlayers.add(p.id);
      _scores[p.id] = result;
      _recalcWinner();
      _autoDetect();
    });
  }

  void _recalcWinner() {
    if (_winnerId == null) return;
    // Running total: sum of whatever losers have been entered so far.
    // Winner's score updates live as each loser is filled in.
    final losers = widget.players.where((p) => p.id != _winnerId);
    final total = losers.fold<int>(0, (s, p) => s + (_scores[p.id] ?? 0));
    _scores[_winnerId!] = -total; // positive running total
  }

  void _autoDetect() {
    if (_winnerId != null) return;
    final noScore = widget.players.where((p) => _scores[p.id] == null).toList();
    final losers = widget.players.where((p) => (_scores[p.id] ?? 0) < 0).toList();
    if (noScore.length == 1 && losers.length == widget.players.length - 1) {
      _winnerId = noScore.first.id;
      _recalcWinner();
    }
  }

  void _tapWin(String pid) {
    _customPlayers.remove(pid);
    setState(() {
      if (_winnerId == pid) {
        _winnerId = null;
        _scores[pid] = null;
      } else {
        if (_winnerId != null) _scores[_winnerId!] = null;
        _winnerId = pid;
        _scores[pid] = null;
        _recalcWinner();
      }
    });
  }

  void _tapLoser(String pid, int value) {
    if (pid == _winnerId) { _winnerId = null; }
    _customPlayers.remove(pid); // a quick button overrides a custom entry
    setState(() {
      _scores[pid] = (_scores[pid] == value) ? null : value;
      _recalcWinner();
      _autoDetect();
    });
  }

  int get _total => _scores.values.fold<int>(0, (s, v) => s + (v ?? 0));

  // Round is "balanced" when all players have scores and they sum to zero.
  bool get _balanced {
    if (widget.players.any((p) => _scores[p.id] == null)) return false;
    return _total == 0;
  }

  // Allow submitting as long as at least one score is entered — the user can
  // come back and finish/edit later from the main scoreboard.
  bool get _canSubmit => _scores.values.any((v) => v != null);

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _busy = true);
    final round = Round(
      id: 'round_${widget.roundNumber}',
      roundNumber: widget.roundNumber,
      winnerPlayerId: _winnerId ?? '',
      scores: Map<String, int>.fromEntries(
          _scores.entries.where((e) => e.value != null).map((e) => MapEntry(e.key, e.value!))),
      total: _total,
    );
    final err = widget.isEdit
        ? await widget.ctrl.editRound(round)
        : await widget.ctrl.submitRound(round, playerCount: widget.players.length);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _total;
    final balanced = _balanced;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: GradientAppBar(
        title: widget.isEdit ? 'Edit Round ${widget.roundNumber}' : 'Round ${widget.roundNumber}',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: balanced ? Colors.white : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  balanced ? '✓  0' : 'Total: ${total > 0 ? '+$total' : '$total'}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                    color: balanced ? const Color(0xFF2E7D32) : Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            itemCount: widget.players.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final p = widget.players[i];
              return _PlayerCard(
                player: p,
                index: i,
                score: _scores[p.id],
                isWinner: _winnerId == p.id,
                // Disable the Winner button when someone else is the winner.
                winnerDisabled: _winnerId != null && _winnerId != p.id,
                isCustom: _customPlayers.contains(p.id),
                onWin: () => _tapWin(p.id),
                onLoser: (v) => _tapLoser(p.id, v),
                onCustomTap: () => _openCustomDialog(p),
              );
            },
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2))],
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_canSubmit && !_busy) ? _submit : null,
              child: _busy
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(widget.isEdit
                      ? 'Save Changes'
                      : balanced ? 'Submit Round ${widget.roundNumber}' : 'Save Round'),
            ),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Player Card (inside score entry page)
// ═══════════════════════════════════════════════════════════════════════════════

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.player, required this.index, required this.score,
    required this.isWinner, required this.winnerDisabled, required this.isCustom,
    required this.onWin, required this.onLoser, required this.onCustomTap,
  });
  final Player player;
  final int index;
  final int? score;
  final bool isWinner;
  final bool winnerDisabled;  // another player is already the winner
  final bool isCustom;        // true when the score was entered via custom dialog
  final VoidCallback onWin;
  final ValueChanged<int> onLoser;
  final VoidCallback onCustomTap;

  bool get _isCustom => isCustom && !isWinner && score != null;

  // A quick button is selected only when the score matches AND it did not come
  // from the custom field.
  bool _isQ(int v) => !isWinner && !_isCustom && score == v;

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFC62828);
    const green = Color(0xFF2E7D32);
    final hasScore = score != null;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isWinner ? green.withValues(alpha: 0.5)
              : hasScore ? red.withValues(alpha: 0.3)
              : const Color(0xFFDDE3F0),
          width: (isWinner || hasScore) ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(children: [
          // ── Row 1: Avatar + name + score pill ............. Winner (right edge) ──
          Row(children: [
            PlayerAvatar(name: player.name, index: index, radius: 18, fontSize: 13),
            const SizedBox(width: 10),
            // Name takes all free space, pushing score + Winner to the right edge
            Expanded(
              child: Text(player.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                overflow: TextOverflow.ellipsis),
            ),
            if (hasScore) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: isWinner ? green : red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  score! > 0 ? '+$score' : '$score',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Winner button — flush at the right edge. Disabled (greyed out)
            // when another player is already the winner.
            GestureDetector(
              onTap: winnerDisabled ? null : onWin,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: winnerDisabled
                      ? const Color(0xFFE0E0E0)
                      : isWinner ? green : green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: winnerDisabled
                        ? const Color(0xFFBDBDBD)
                        : isWinner ? green : green.withValues(alpha: 0.4),
                    width: isWinner ? 1.5 : 1),
                ),
                child: Text(isWinner ? '🏆 Winner' : 'Winner',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: winnerDisabled
                        ? const Color(0xFF9E9E9E)
                        : isWinner ? Colors.white : green)),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          // ── Row 2: Scoot | Quit | Full | Custom (ascending points) ──
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            _LoseBtn(label: 'Scoot', sub: '${AppConstants.scoreScoot}',
              shade: 0, // lightest (−20)
              selected: _isQ(AppConstants.scoreScoot),
              onTap: () => onLoser(AppConstants.scoreScoot)),
            const SizedBox(width: 6),
            _LoseBtn(label: 'Quit', sub: '${AppConstants.scoreQuit}',
              shade: 1, // medium (−40)
              selected: _isQ(AppConstants.scoreQuit),
              onTap: () => onLoser(AppConstants.scoreQuit)),
            const SizedBox(width: 6),
            _LoseBtn(label: 'Full', sub: '${AppConstants.scoreFull}',
              shade: 2, // darkest (−80)
              selected: _isQ(AppConstants.scoreFull),
              onTap: () => onLoser(AppConstants.scoreFull)),
            const SizedBox(width: 6),
            // Custom button — opens a dialog; shows captured value like others
            Expanded(
              child: GestureDetector(
                onTap: onCustomTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isCustom ? red : red.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isCustom ? red : red.withValues(alpha: 0.3),
                      width: _isCustom ? 1.5 : 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Custom',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: _isCustom ? Colors.white : red)),
                      Text(
                        _isCustom ? '$score' : 'Tap',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
                          color: _isCustom ? Colors.white.withValues(alpha: 0.9)
                                           : red.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── Lose quick-pick button ────────────────────────────────────────────────────

class _LoseBtn extends StatelessWidget {
  const _LoseBtn({
    required this.label, required this.sub, required this.selected,
    required this.onTap, this.shade = 0,
  });
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;
  final int shade; // 0 = lightest (fewest points), 2 = darkest (most points)

  // Progressively deeper red by severity.
  static const List<Color> _reds = [
    Color(0xFFEF9A9A), // −20 Scoot (very light)
    Color(0xFFE57373), // −40 Quit  (light-medium)
    Color(0xFFC62828), // −80 Full  (deep)
  ];

  // Uniform deep red used for ALL selected buttons.
  static const Color _selectedRed = Color(0xFFC62828);

  @override
  Widget build(BuildContext context) {
    final c = _reds[shade.clamp(0, 2)]; // per-severity tint (unselected only)
    final blur = 2.0 + shade * 3.0;
    final spread = shade.toDouble();
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            // Selected: single uniform red. Unselected: light per-severity tint.
            color: selected ? _selectedRed : c.withValues(alpha: 0.10 + shade * 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? _selectedRed : c.withValues(alpha: 0.35),
              width: selected ? 1.5 : 1),
            boxShadow: [
              BoxShadow(
                color: (selected ? _selectedRed : c).withValues(alpha: selected ? 0.45 : 0.18),
                blurRadius: blur,
                spreadRadius: spread,
                offset: Offset(0, 1 + shade.toDouble()),
              ),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: selected ? Colors.white : _selectedRed)),
            Text(sub, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900,
              color: selected ? Colors.white.withValues(alpha: 0.9) : _selectedRed)),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Final Results Screen
// ═══════════════════════════════════════════════════════════════════════════════

class _FinalResultsScreen extends StatelessWidget {
  const _FinalResultsScreen({required this.ctrl, required this.onBack});
  final GameController ctrl;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final game = ctrl.game!;
    final players = ctrl.players;
    final totals = ctrl.totals;
    final sorted = [...players]..sort((a, b) => (totals[b.id] ?? 0).compareTo(totals[a.id] ?? 0));
    final winner = sorted.isNotEmpty ? sorted.first : null;
    final winnerScore = winner != null ? (totals[winner.id] ?? 0) : 0;

    return Scaffold(
      appBar: const GradientAppBar(title: 'Game Complete', subtitle: 'Final Results'),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        if (winner != null) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              const Text('🏆', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              const Text('GAME COMPLETE',
                style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(winner.name, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              Text(winnerScore > 0 ? '+$winnerScore points' : '$winnerScore points',
                style: const TextStyle(color: Colors.white70, fontSize: 18)),
            ]),
          ),
          const SizedBox(height: 20),
        ],
        const Text('Final Scores',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 12),
        Card(
          child: Column(children: [
            for (var i = 0; i < sorted.length; i++) ...[
              _FinalScoreRow(
                player: sorted[i],
                index: players.indexOf(sorted[i]),
                score: totals[sorted[i].id] ?? 0,
                rank: i + 1,
              ),
              if (i < sorted.length - 1) const Divider(height: 1, indent: 56),
            ],
          ]),
        ),
        const SizedBox(height: 12),
        Center(child: Text('${game.totalRounds} Rounds Played',
          style: const TextStyle(color: Color(0xFF5A6080), fontSize: 14))),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: onBack, child: const Text('Back to Home')),
      ]),
    );
  }
}

class _FinalScoreRow extends StatelessWidget {
  const _FinalScoreRow({required this.player, required this.index, required this.score, required this.rank});
  final Player player;
  final int index;
  final int score;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final color = score > 0 ? AppTheme.scorePositive
        : score < 0 ? AppTheme.scoreNegative
        : AppTheme.scoreNeutral;
    final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '#$rank';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        SizedBox(width: 28,
          child: Text(medal, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center)),
        const SizedBox(width: 10),
        PlayerAvatar(name: player.name, index: index, radius: 18, fontSize: 13),
        const SizedBox(width: 12),
        Expanded(child: Text(player.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
        Text(score > 0 ? '+$score' : '$score',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ]),
    );
  }
}
