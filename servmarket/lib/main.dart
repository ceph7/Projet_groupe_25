import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ServMarketApp());
}

class ServMarketApp extends StatelessWidget {
  const ServMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ServMarket',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const FirebaseStatusScreen(),
    );
  }
}

class FirebaseStatusScreen extends StatelessWidget {
  const FirebaseStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projectId = Firebase.apps.isEmpty
        ? 'Firebase non initialisé'
        : Firebase.app().options.projectId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ServMarket'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            SizedBox(height: 16),
            Text(
              'Firebase connecté ✅',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Projet : $projectId',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

}