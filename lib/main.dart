import 'package:flutter/material.dart';
import 'package:pokemon_card/background_blur.dart';
import 'package:pokemon_card/tilt_card.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter 3D Pokemon Card',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 배경 이미지
            BackgroudBlur(),
            // 메인 카드
            Center(
              child: TiltCard(),
            ),
          ],
        ),
      ),
    );
  }
}

