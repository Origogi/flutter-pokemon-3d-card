import 'package:flutter/material.dart';
import 'dart:ui'; // ImageFilter를 사용하기 위한 import
import 'package:flutter/rendering.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Pokemon Card (as overlay)
          Center(
            child: Container(
              width: 250,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFFC83C),
                  width: 10,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 200,
                    offset: Offset(0, 50),
                    spreadRadius: -25,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    // Pokemon Name
                    Text(
                      'Pikachu',
                      style: TextStyle(
                        fontFamily: 'Silkscreen',
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),

                    Text(
                      '65HP',
                      style: TextStyle(
                        fontFamily: 'Silkscreen',
                        fontSize: 16,
                        color: Color(0xFFFFC83C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Pokemon Image with positioning
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.3, // 10%
            left: MediaQuery.of(context).size.width * 0.4, // 50%
            child: Transform(
              transform: Matrix4.identity()
                ..translate(
                    -125.0, 0, 100.0), // translateX(-50%) and translateZ(100px)
              child: SizedBox(
                width: 300,
                height: 300,
                child: Image.network(
                  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
