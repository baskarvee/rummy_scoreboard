import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/widgets/gradient_app_bar.dart';
import '../data/game_repository.dart';

class JoinGameScreen extends StatefulWidget {
  const JoinGameScreen({
    super.key,
    required this.userId,
    required this.repo,
    this.initialCode,
  });
  final String userId;
  final GameRepository repo;
  final String? initialCode;

  @override
  State<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends State<JoinGameScreen> {
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null) {
      _codeCtrl.text = widget.initialCode!.toUpperCase();
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    final name = _nameCtrl.text.trim();

    if (code.length != AppConstants.codeLength) {
      setState(() => _error = 'Enter the 6-character game code.');
      return;
    }
    if (name.isEmpty) {
      setState(() => _error = 'Enter your name.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final game = await widget.repo.findGameByCode(code);
      if (game == null) {
        setState(() => _error = 'Game not found. Check the 6-character code.');
        return;
      }
      if (game.isCompleted) {
        setState(() => _error = 'This game has already ended.');
        return;
      }

      // Check player count
      // We'll check inside addPlayer — but first do a quick count via stream snapshot
      await widget.repo.addPlayer(
        gameId: game.id,
        name: name,
        userId: widget.userId,
        currentRound: game.currentRound,
      );

      if (mounted) Navigator.pop(context, game);
    } catch (e) {
      setState(() => _error = 'Error joining game: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Join with Code'),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 16),
          // Icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE1ECF8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text('🃏', style: TextStyle(fontSize: 36)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Join a Game',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Enter the 6-character code and your name\nto join an existing game.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF5A6080), fontSize: 14),
            ),
          ),
          const SizedBox(height: 28),
          // Code field
          const _FieldLabel('Game Code'),
          TextFormField(
            controller: _codeCtrl,
            decoration: InputDecoration(
              hintText: 'R7K2P9',
              suffixIcon: _codeCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () =>
                          setState(() => _codeCtrl.clear()),
                    )
                  : null,
            ),
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              letterSpacing: 4,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
            onChanged: (v) {
              _codeCtrl.value = _codeCtrl.value.copyWith(
                text: v.toUpperCase(),
                selection: TextSelection.collapsed(offset: v.length),
              );
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          // Name field
          const _FieldLabel('Your Name'),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              hintText: 'Enter your name',
              prefixIcon: Icon(Icons.person_outline, size: 18),
            ),
            textCapitalization: TextCapitalization.words,
            onEditingComplete: _join,
          ),
          const SizedBox(height: 8),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFBE3E1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Color(0xFFC62828), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                          color: Color(0xFFC62828), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _busy ? null : _join,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Join Game'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE1ECF8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: Color(0xFF1565C0)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ask the host for the 6-character game code. '
                    'You can join a game even after it has already started.',
                    style:
                        TextStyle(fontSize: 12, color: Color(0xFF5A6080)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Color(0xFF1A1A2E),
        ),
      ),
    );
  }
}
