import 'package:flutter/material.dart';
import 'package:ui_qna_module/features/onscreen_qna/screens/qna_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: QnaScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}