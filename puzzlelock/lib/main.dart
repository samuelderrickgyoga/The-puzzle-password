import 'package:flutter/material.dart';
import 'puzzle.dart'; // Import your puzzle screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Number Puzzle Authentication',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const NumberPuzzleScreen(), // Set the home screen to NumberPuzzleScreen
      debugShowCheckedModeBanner: false, // Remove the debug banner
    );
  }
}
