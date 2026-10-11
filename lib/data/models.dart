import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Game ────────────────────────────────────────────────────────────────────

enum GameStatus { inProgress, completed }

class Game {
  const Game({
    required this.id,
    required this.name,
    required this.code,
    required this.hostUserId,
    required this.totalRounds,
    required this.currentRound,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String code;
  final String hostUserId;
  final int totalRounds;
  final int currentRound;
  final GameStatus status;
  final DateTime createdAt;

  bool get isCompleted => status == GameStatus.completed;
  bool get isInProgress => status == GameStatus.inProgress;

  factory Game.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Game(
      id: doc.id,
      name: d['name'] as String? ?? 'Rummy Game',
      code: d['code'] as String? ?? '',
      hostUserId: d['hostUserId'] as String? ?? '',
      totalRounds: (d['totalRounds'] as num?)?.toInt() ?? 10,
      currentRound: (d['currentRound'] as num?)?.toInt() ?? 1,
      status: (d['status'] as String?) == 'COMPLETED'
          ? GameStatus.completed
          : GameStatus.inProgress,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'code': code,
        'hostUserId': hostUserId,
        'totalRounds': totalRounds,
        'currentRound': currentRound,
        'status': status == GameStatus.completed ? 'COMPLETED' : 'IN_PROGRESS',
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Game copyWith({
    String? name,
    int? currentRound,
    GameStatus? status,
  }) =>
      Game(
        id: id,
        name: name ?? this.name,
        code: code,
        hostUserId: hostUserId,
        totalRounds: totalRounds,
        currentRound: currentRound ?? this.currentRound,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}

// ─── Player ──────────────────────────────────────────────────────────────────

class Player {
  const Player({
    required this.id,
    required this.name,
    this.userId,
    this.isGuest = true,
    this.joinedAtRound = 1,
  });

  final String id;
  final String name;
  final String? userId;
  final bool isGuest;
  final int joinedAtRound;

  factory Player.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Player(
      id: doc.id,
      name: d['name'] as String? ?? 'Player',
      userId: d['userId'] as String?,
      isGuest: d['isGuest'] as bool? ?? true,
      joinedAtRound: (d['joinedAtRound'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'userId': userId,
        'isGuest': isGuest,
        'joinedAtRound': joinedAtRound,
      };
}

// ─── Round ───────────────────────────────────────────────────────────────────

class Round {
  const Round({
    required this.id,
    required this.roundNumber,
    required this.winnerPlayerId,
    required this.scores,
    required this.total,
  });

  final String id;
  final int roundNumber;
  final String winnerPlayerId;
  /// playerId -> score (positive for winner, negative for losers)
  final Map<String, int> scores;
  final int total;

  factory Round.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final rawScores = (d['scores'] as Map<String, dynamic>?) ?? {};
    return Round(
      id: doc.id,
      roundNumber: (d['roundNumber'] as num?)?.toInt() ?? 0,
      winnerPlayerId: d['winnerPlayerId'] as String? ?? '',
      scores: rawScores.map((k, v) => MapEntry(k, (v as num).toInt())),
      total: (d['total'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'roundNumber': roundNumber,
        'winnerPlayerId': winnerPlayerId,
        'scores': scores,
        'total': total,
      };

  Round copyWith({
    String? winnerPlayerId,
    Map<String, int>? scores,
    int? total,
  }) =>
      Round(
        id: id,
        roundNumber: roundNumber,
        winnerPlayerId: winnerPlayerId ?? this.winnerPlayerId,
        scores: scores ?? this.scores,
        total: total ?? this.total,
      );
}
