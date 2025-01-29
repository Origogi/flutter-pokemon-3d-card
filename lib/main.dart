import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:ui'; // ImageFilter를 사용하기 위한 import
import 'dart:math';
import 'package:flutter/foundation.dart'; 

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
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 이미지
          SizedBox(
            width: 800,
            height: 800,
            child: ColorFiltered(
              // saturation과 contrast 모두 증가
              colorFilter: const ColorFilter.matrix([
                2.5, -0.5, -0.5, 0, 0,    // Red
                -0.5, 2.5, -0.5, 0, 0,    // Green
                -0.5, -0.5, 2.5, 0, 0,    // Blue
                0, 0, 0, 1.2, 0,          // Alpha
              ]),
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.1),
                    ],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.multiply,
                child: Image.network(
                  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/25.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // 블러 효과와 채도 강화
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 150,
              sigmaY: 150,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.15),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // 메인 카드
          const Center(
            child: TiltCard(),
          ),
        ],
      ),
    );
  }
}


class TiltCard extends StatefulWidget {
  const TiltCard({super.key});

  @override
  TiltCardState createState() => TiltCardState();
}

class TiltCardState extends State<TiltCard>
    with SingleTickerProviderStateMixin {
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  late AnimationController _controller;

  double get _glareOpacity =>
      ((_tiltX.abs() + _tiltY.abs()) / 20) * 0.35;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..drive(CurveTween(
        curve: const Cubic(0.03, 0.35, 0.63, 1.23),
      ));
  }

  void _onMouseMove(PointerHoverEvent event, BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(event.position);

    setState(() {
      final centerX = renderBox.size.width / 2;
      final centerY = renderBox.size.height / 2;
      _tiltX = -(localPosition.dy - centerY) / 20;
      _tiltY = -(localPosition.dx - centerX) / 20;
      _tiltX = _tiltX.clamp(-8.0, 8.0);
      _tiltY = _tiltY.clamp(-8.0, 8.0);
    });
  }

  void _onPointerMove(Offset position) {
    setState(() {
      _tiltX = -(position.dy - 200) / 20;
      _tiltY = -(position.dx - 125) / 20;
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
      child: kIsWeb
          ? MouseRegion(
              onHover: (event) => _onMouseMove(event, context),
              onExit: (_) => _resetTilt(),
              child: _buildTiltCard(context),
            )
          : GestureDetector(
              onPanStart: (details) {
                _onPointerMove(details.localPosition);
              },
              onPanUpdate: (details) {
                _onPointerMove(details.localPosition);
              },
              onPanEnd: (_) {
                _resetTilt();
              },
              child: _buildTiltCard(context),
            ),
    );
  }

  Widget _buildTiltCard(BuildContext context) {
    return AnimatedBuilder(
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
              // 카드 배경
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
                child: const Stack(
                  children: [
                    Padding(
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
                              fontWeight: FontWeight.bold,
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
                  ],
                ),
              ),
              // 카드 내부 이미지 (카드와 함께 틸트됨)
              Positioned(
                bottom: -20,
                left: 0,
                right: 0,
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // 3D 효과를 위한 Z축 설정
                    ..rotateX(_tiltX * (pi / 180)) // 카드와 동일한 틸트 적용
                    ..rotateY(_tiltY * (pi / 180)) // 카드와 동일한 틸트 적용
                    ..translate(0.0, 0.0, -100.0), // Z축 이동
                  alignment: FractionalOffset.center,
                  child: SizedBox(
                    width: 350,
                    height: 350,
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
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
