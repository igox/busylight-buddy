import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: BusylightApp()));
}

class BusylightApp extends StatelessWidget {
  const BusylightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusyLight',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.amber,
          secondary: Colors.amber.shade700,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
