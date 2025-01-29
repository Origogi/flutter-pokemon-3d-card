import 'package:flutter/material.dart';
import 'dart:ui'; // ImageFilter를 사용하기 위한 import
import 'package:flutter/rendering.dart';
import 'dart:math';

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
          TiltCard(),
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

class TiltCard extends StatefulWidget {
  @override
  _TiltCardState createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> with SingleTickerProviderStateMixin {
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  late AnimationController _controller;
  late Animation<double> _animationX;
  late Animation<double> _animationY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _animationX = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);
    _animationY = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);
  }

  void _onPointerMove(Offset position) {
    setState(() {
      // 화면 크기 기반으로 기울기 계산
      _tiltX = (position.dy - 200) / 20; // 최대 기울기 조정
      _tiltY = (position.dx - 125) / 20; // 최대 기울기 조정

      // 최대 기울기 제한
      _tiltX = _tiltX.clamp(-20.0, 20.0); // maxTilt
      _tiltY = _tiltY.clamp(-20.0, 20.0); // maxTilt
    });
  }

  void _resetTilt() {
    _controller.forward(from: 0.0).then((_) {
      setState(() {
        _tiltX = 0.0;
        _tiltY = 0.0;
      });
      _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onPanStart: (details) {
          _onPointerMove(details.localPosition); // 터치 시작 시 기울기 적용
        },
        onPanUpdate: (details) {
          _onPointerMove(details.localPosition); // localPosition으로 변경
        },
        onPanEnd: (_) {
          _resetTilt(); // 터치를 땐 순간 원상복귀
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // 원근감 추가
                ..rotateX(_tiltX * (pi / 180) * (1 - _controller.value)) // X축 회전
                ..rotateY(_tiltY * (pi / 180) * (1 - _controller.value)), // Y축 회전
              alignment: FractionalOffset.center,
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
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}