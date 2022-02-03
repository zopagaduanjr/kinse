import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kinse/screen/puzzle_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: kIsWeb
        ? const FirebaseOptions(
            apiKey: "AIzaSyAaZti2O1LyTf0IdV2HjPKOVBA02B92l1I",
            appId: "1:707553157821:web:4643b20a55f75ff43f0dd4",
            messagingSenderId: "707553157821",
            projectId: "kinse-6c9f3")
        : null,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kinse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const PuzzleScreen(),
    );
  }
}
