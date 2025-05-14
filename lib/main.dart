import 'package:appnotes/edit_note_screen.dart';
import 'package:appnotes/home_screen.dart';
import 'package:appnotes/login_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp()); // Esta es la línea que faltaba
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
