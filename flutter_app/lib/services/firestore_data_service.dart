import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../config/app_config.dart';

class FirestoreDataService {
  const FirestoreDataService._();

  static FirebaseFirestore? get instance {
    if (!AppConfig.isFirebaseConfigured || Firebase.apps.isEmpty) {
      return null;
    }

    return FirebaseFirestore.instance;
  }
}