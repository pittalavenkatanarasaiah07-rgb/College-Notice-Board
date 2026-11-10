
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'screens/auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: 'https://njvdsvcfyylvrcwzgnya.supabase.co',
    publishableKey: 'sb_publishable_Mm2g2hVzKIYG7WrrXwbIgg_UllV-ZoY',
  );

  runApp(const CollegeNoticeBoardApp());
}

class CollegeNoticeBoardApp extends StatelessWidget {
  const CollegeNoticeBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'College Notice Board',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}
