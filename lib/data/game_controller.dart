import 'dart:async';
import 'package:flutter/foundation.dart';
import 'models.dart';
import 'game_repository.dart';

/// Holds live state for a single open game.
class GameController extends ChangeNotifier {
  GameController({
    required this.gameId,
    required GameRepository repository,
  }) : _repo = repository {
    _gameSub = _repo.watchGame(gameId).listen((g) {
      _game = g;
      notifyListeners();
    });
    _playersSub = _repo.watchPlayers(gameId).listen((p) {
      _players = p;
      notifyListeners();
    });
    _roundsSub = _repo.watchRounds(gameId).listen((r) {
      _rounds = r;
      notifyListeners();
    });
  }

  final String gameId;
  final GameRepository _repo;

  Game? _game;
  List<Player> _players = [];
  List<Round> _rounds = [];
  bool _busy = false;
  String? _error;

  Game? get game => _game;
  List<Player> get players => _players;
  List<Round> get rounds => _rounds;
  bool get busy => _busy;
  String? get error => _error;

  StreamSubscription<Game>? _gameSub;
  StreamSubscription<List<Player>>? _playersSub;
  StreamSubscription<List<Round>>? _roundsSub;

  // ── Computed totals ───────────────────────────────────────────────────────

  /// Returns cumulative score per playerId across all submitted rounds.
  Map<String, int> get totals {
    final result = <String, int>{};
    for (final p in _players) { result[p.id] = 0; }
    for (final r in _rounds) {
      r.scores.forEach((pid, score) {
        result[pid] = (result[pid] ?? 0) + score;
      });
    }
    return result;
  }

  /// Number of times each player scored a Scoot (−20) across the game.
  Map<String, int> get scootCounts {
    final result = <String, int>{};
    for (final p in _players) { result[p.id] = 0; }
    for (final r in _rounds) {
      r.scores.forEach((pid, score) {
        if (score == -20) result[pid] = (result[pid] ?? 0) + 1;
      });
    }
    return result;
  }

  /// Score for a specific player in a specific round (null = not yet played).
  int? scoreFor(String playerId, int roundNumber) {
    final round = _rounds.where((r) => r.roundNumber == roundNumber).firstOrNull;
    if (round == null) return null;
    return round.scores[playerId];
  }

  Round? roundByNumber(int n) =>
      _rounds.where((r) => r.roundNumber == n).firstOrNull;

  // ── Submit round ──────────────────────────────────────────────────────────

  /// Saves a round. Advances to the next round only when the round is fully
  /// balanced (all players scored and the total is zero). A partially-filled
  /// round is saved in place so the user can return and finish it later.
  Future<String?> submitRound(Round round, {int playerCount = 0}) async {
    final g = _game;
    if (g == null) return 'Game not loaded.';
    final allScored = playerCount > 0 && round.scores.length >= playerCount;
    final balanced = allScored && round.total == 0;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final nextRound = g.currentRound + 1;
      final isLast = g.currentRound >= g.totalRounds;
      await _repo.submitRound(
        gameId: gameId,
        round: round,
        nextRound: nextRound,
        isLastRound: isLast,
        advance: balanced, // only move forward when the round balances
      );
      return null;
    } catch (e) {
      _error = e.toString();
      return _error;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String?> editRound(Round round) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.editRound(gameId: gameId, round: round);
      return null;
    } catch (e) {
      _error = e.toString();
      return _error;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _gameSub?.cancel();
    _playersSub?.cancel();
    _roundsSub?.cancel();
    super.dispose();
  }
}
