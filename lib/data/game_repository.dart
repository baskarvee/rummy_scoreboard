import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import 'models.dart';

class GameRepository {
  GameRepository() : _db = FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _games =>
      _db.collection('games');

  // ── Code generation ──────────────────────────────────────────────────────

  String _generateCode() {
    final rand = Random.secure();
    final chars = AppConstants.codeCharset;
    return List.generate(
      AppConstants.codeLength,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
  }

  // ── Create game ──────────────────────────────────────────────────────────

  Future<Game> createGame({
    required String name,
    required int totalRounds,
    required String hostUserId,
    required List<String> playerNames,
  }) async {
    final code = _generateCode();
    final ref = _games.doc();
    final game = Game(
      id: ref.id,
      name: name.trim().isEmpty ? 'Rummy Game' : name.trim(),
      code: code,
      hostUserId: hostUserId,
      totalRounds: totalRounds,
      currentRound: 1,
      status: GameStatus.inProgress,
      createdAt: DateTime.now(),
    );

    // Step 1: Write the game document first so it exists before player rules
    // try to do a get() on it.
    await ref.set(game.toMap());

    // Step 2: Write all players in a separate batch now that the game exists.
    final batch = _db.batch();
    for (final pName in playerNames) {
      final pRef = ref.collection('players').doc();
      final isHost = pName == playerNames.first;
      batch.set(pRef, Player(
        id: pRef.id,
        name: pName.trim(),
        userId: isHost ? hostUserId : null,
        isGuest: !isHost,
        joinedAtRound: 1,
      ).toMap());
    }
    await batch.commit();
    return game;
  }

  // ── Join game ─────────────────────────────────────────────────────────────

  Future<Game?> findGameByCode(String code) async {
    final upper = code.trim().toUpperCase();
    final snap = await _games
        .where('code', isEqualTo: upper)
        .where('status', isEqualTo: 'IN_PROGRESS')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Game.fromDoc(snap.docs.first);
  }

  Future<String> addPlayer({
    required String gameId,
    required String name,
    required String? userId,
    required int currentRound,
  }) async {
    final pRef = _games.doc(gameId).collection('players').doc();
    await pRef.set(Player(
      id: pRef.id,
      name: name.trim(),
      userId: userId,
      isGuest: userId == null,
      joinedAtRound: currentRound,
    ).toMap());
    return pRef.id;
  }

  // ── Streams ───────────────────────────────────────────────────────────────

  Stream<Game> watchGame(String gameId) {
    return _games.doc(gameId).snapshots().map(Game.fromDoc);
  }

  Stream<List<Player>> watchPlayers(String gameId) {
    return _games
        .doc(gameId)
        .collection('players')
        .orderBy('joinedAtRound')
        .snapshots()
        .map((s) => s.docs.map(Player.fromDoc).toList());
  }

  Stream<List<Round>> watchRounds(String gameId) {
    return _games
        .doc(gameId)
        .collection('rounds')
        .orderBy('roundNumber')
        .snapshots()
        .map((s) => s.docs.map(Round.fromDoc).toList());
  }

  // ── My games list (for home) ──────────────────────────────────────────────

  Stream<List<Game>> watchMyGames(String userId) {
    return _games
        .where('hostUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Game.fromDoc).toList());
  }

  Future<List<Game>> getGamesWherePlayer(String userId) async {
    // Supplementary: also find games where user joined as non-host
    // This is a best-effort query; Firestore doesn't support collection-group
    // queries with per-document auth easily at MVP level.
    return [];
  }

  // ── Submit / edit round ───────────────────────────────────────────────────

  /// Saves the round. When [advance] is true, also moves the game to the next
  /// round (or marks it COMPLETED on the final round). When false, only the
  /// round scores are persisted so the user can return and finish it later.
  Future<void> submitRound({
    required String gameId,
    required Round round,
    required int nextRound,
    required bool isLastRound,
    bool advance = true,
  }) async {
    final batch = _db.batch();
    final rRef = _games
        .doc(gameId)
        .collection('rounds')
        .doc('round_${round.roundNumber}');
    batch.set(rRef, round.toMap());
    if (advance) {
      batch.update(_games.doc(gameId), {
        'currentRound': isLastRound ? nextRound - 1 : nextRound,
        'status': isLastRound ? 'COMPLETED' : 'IN_PROGRESS',
      });
    }
    await batch.commit();
  }

  Future<void> editRound({
    required String gameId,
    required Round round,
  }) async {
    final rRef = _games
        .doc(gameId)
        .collection('rounds')
        .doc('round_${round.roundNumber}');
    await rRef.set(round.toMap());
  }

  // ── Delete game ───────────────────────────────────────────────────────────

  Future<void> deleteGame(String gameId) async {
    // Delete subcollections first (players + rounds)
    final batch = _db.batch();
    final players = await _games.doc(gameId).collection('players').get();
    final rounds = await _games.doc(gameId).collection('rounds').get();
    for (final d in players.docs) { batch.delete(d.reference); }
    for (final d in rounds.docs) { batch.delete(d.reference); }
    batch.delete(_games.doc(gameId));
    await batch.commit();
  }
}
