import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:workaxis/app/app.dart';
import 'package:workaxis/app/bootstrap/backend_factory.dart';
import 'package:workaxis/app/config/backend_config.dart';
import 'package:workaxis/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A release build must never ship the mock backend (fixture credentials).
  BackendConfig.assertReleaseSafe();

  if (BackendConfig.isFirebase) {
    // Fail clearly: building Firebase repositories on top of an uninitialised
    // Firebase app would only fail later and more confusingly.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  final repositories = BackendConfig.isFirebase
      ? BackendFactory.createRepositories(
          auth: FirebaseAuth.instance,
          firestore: FirebaseFirestore.instance,
        )
      : BackendFactory.createRepositories();

  runApp(WorkAxisApp(repositories: repositories));
}
