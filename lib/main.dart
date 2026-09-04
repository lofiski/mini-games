import 'package:flutter/material.dart';

void main() => runApp(const MiniGamesApp());

class MiniGamesApp extends StatelessWidget {
  const MiniGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Games',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF6750A4)),
      home: const Scaffold(body: Center(child: Text('Mini Games'))),
    );
  }
}
