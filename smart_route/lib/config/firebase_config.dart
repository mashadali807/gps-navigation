import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_route/firebase_options.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  static FirebaseAuth get auth => FirebaseAuth.instance;
}
