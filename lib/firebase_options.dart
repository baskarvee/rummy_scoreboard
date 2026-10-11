// GENERATED FILE — replace with your own Firebase project config.
// Run: flutterfire configure
//
// Placeholder so the project compiles. Replace all values before running.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // REPLACE the values below with those from your Firebase project console.
  // Firebase Console → Project settings → Your apps → SDK config
  // ──────────────────────────────────────────────────────────────────────────

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCZD3bFBnb5mT_QpwlLBJT6nA8Bdh8wUaQ',
    appId: '1:1048501792056:web:c4aee0800543be60d625cd',
    messagingSenderId: '1048501792056',
    projectId: 'rummy-scoreboard-keeper',
    authDomain: 'rummy-scoreboard-keeper.firebaseapp.com',
    storageBucket: 'rummy-scoreboard-keeper.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCab76OJ97EaMHMC6sAK0Y-NH3uRQrtPuA',
    appId: '1:1048501792056:android:6255d6f26cbce291d625cd',
    messagingSenderId: '1048501792056',
    projectId: 'rummy-scoreboard-keeper',
    storageBucket: 'rummy-scoreboard-keeper.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBdgP7Z90Ij8b0mZ8VgxnGv94RqbDUs3iA',
    appId: '1:1048501792056:ios:a762afdce0722e07d625cd',
    messagingSenderId: '1048501792056',
    projectId: 'rummy-scoreboard-keeper',
    storageBucket: 'rummy-scoreboard-keeper.firebasestorage.app',
    iosBundleId: 'com.friends4ever.rummyScoreboard',
  );
}
