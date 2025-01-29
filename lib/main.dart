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
      body: TiltCard(),
    );
  }
}


class TiltCard extends StatefulWidget {
  @override
  _TiltCardState createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard>
    with SingleTickerProviderStateMixin {
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  late AnimationController _controller;
  late Animation<double> _animationX;
  late Animation<double> _animationY;

  // glare 효과를 위한 getter 추가
  double get _glareOpacity => 
      ((_tiltX.abs() + _tiltY.abs()) / 20) * 0.35; // maxGlare: 0.35

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..drive(CurveTween(
        curve: Cubic(0.03, 0.35, 0.63, 1.23), // 원본 CSS의 easing curve
      ));

    _animationX = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);
    _animationY = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);
  }

  void _onPointerMove(Offset position) {
    setState(() {
      _tiltX = (position.dy - 200) / 20;
      _tiltY = (position.dx - 125) / 20;

      // maxTilt: 8로 제한
      _tiltX = _tiltX.clamp(-8.0, 8.0);
      _tiltY = _tiltY.clamp(-8.0, 8.0);
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
          _onPointerMove(details.localPosition);
        },
        onPanUpdate: (details) {
          _onPointerMove(details.localPosition);
        },
        onPanEnd: (_) {
          _resetTilt();
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(_tiltX * (pi / 180) * (1 - _controller.value))
                ..rotateY(_tiltY * (pi / 180) * (1 - _controller.value)),
              alignment: FractionalOffset.center,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
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
                    child: Stack(
                      children: [
                        const Padding(
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
                        // Glare 효과 레이어
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 100),
                          opacity: _glareOpacity,
                          child: Container(
                            width: 250,
                            height: 400,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment(
                                  -_tiltY / 8,
                                  -_tiltX / 8,
                                ),
                                end: Alignment(
                                  _tiltY / 8,
                                  _tiltX / 8,
                                ),
                                colors: [
                                  Colors.white.withOpacity(0.0),
                                  Colors.white.withOpacity(0.5),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: 125,
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..translate(-180.0, 0.0, 50.0),
                      alignment: FractionalOffset.center,
                      child: Container(
                        width: 350,
                        height: 350,
                        child: Image.network(
                          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/151.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
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
