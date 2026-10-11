import 'package:flutter/widgets.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Rummy Score Keeper';

  // Spacing
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 24;

  // Radii
  static const double cardRadius = 16;
  static const double radiusMd = 12;
  static const double radiusSm = 8;
  static const double radiusPill = 999;

  // Scoring shortcuts
  static const int scoreFull = -80;
  static const int scoreScoot = -20;
  static const int scoreQuit = -40;
  static const int minCustomScore = -80;
  static const int maxCustomScore = -1;

  // Game rules
  static const int minPlayers = 2;
  static const int maxPlayers = 10;
  static const int defaultRounds = 10;
  static const int maxRounds = 30;
  static const int minRounds = 1;

  // Code charset — no O/0 or I/1 ambiguity
  static const String codeCharset = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const int codeLength = 6;

  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;
}
