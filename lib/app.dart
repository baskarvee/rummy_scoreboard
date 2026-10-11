import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'screens/home_screen.dart';

class RummyApp extends StatelessWidget {
  const RummyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AuthGate(),
    );
  }
}

/// Signs in anonymously and shows HomeScreen once authenticated.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  String? _userId;
  String? _error;
  bool _timedOut = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _signIn();
    _timer = Timer(const Duration(seconds: 12), () {
      if (mounted && _userId == null) {
        setState(() => _timedOut = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _signIn() async {
    try {
      // Re-use existing anonymous session if present
      var user = FirebaseAuth.instance.currentUser;
      user ??= (await FirebaseAuth.instance.signInAnonymously()).user;
      if (mounted) setState(() => _userId = user?.uid);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId != null) {
      return HomeScreen(userId: _userId!);
    }

    // Loading / error splash
    return Scaffold(
      body: Container(
        decoration: AppTheme.headerDecoration,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🃏', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                'Rummy Score Keeper',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Keep score. Play more.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 32),
              if (_error != null || _timedOut) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _error ??
                        'Connection timed out.\nEnsure Anonymous sign-in is enabled in Firebase.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _timedOut = false;
                    });
                    _signIn();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    minimumSize: const Size(140, 44),
                  ),
                  child: const Text('Retry'),
                ),
              ] else
                const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
