import 'package:flutter/material.dart'; // ESTA IMPORTACIÓN ES NECESARIA

import 'edit_note_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOTES',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/': (context) => const HomeScreen(),
        '/edit': (context) => const EditNoteScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
