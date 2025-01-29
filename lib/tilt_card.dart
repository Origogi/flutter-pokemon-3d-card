

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

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
  late Animation<double> _tiltXAnimation;
  late Animation<double> _tiltYAnimation;

  double get _glareOpacity =>
      ((_tiltX.abs() + _tiltY.abs()) / 20) * 0.35;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // 초기 애니메이션 설정 (0에서 시작)
    _tiltXAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(_controller)
      ..addListener(() {
        setState(() {
          _tiltX = _tiltXAnimation.value;
        });
      });

    _tiltYAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(_controller)
      ..addListener(() {
        setState(() {
          _tiltY = _tiltYAnimation.value;
        });
      });
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
    // 기존 값을 애니메이션의 시작 값으로 설정
    _tiltXAnimation = Tween<double>(begin: _tiltX, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _tiltYAnimation = Tween<double>(begin: _tiltY, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    // 애니메이션 실행
    _controller.forward(from: 0.0);
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
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(_tiltX * (pi / 180))
        ..rotateY(_tiltY * (pi / 180)),
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
                // Glare 효과
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        begin: Alignment(
                          -0.5 - _tiltY / 8,  // tilt에 따라 시작점 이동
                          -0.5 + _tiltX / 8,
                        ),
                        end: Alignment(
                          0.5 - _tiltY / 8,   // tilt에 따라 끝점 이동
                          0.5 + _tiltX / 8,
                        ),
                        colors: [
                          Colors.white.withOpacity(_glareOpacity),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
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
                ..setEntry(3, 2, 0.001)
                ..rotateX(_tiltX * (pi / 180))
                ..rotateY(_tiltY * (pi / 180))
                ..translate(0.0, 0.0, -100.0),
              alignment: FractionalOffset.center,
              child: SizedBox(
                width: 350,
                height: 350,
                child: Image.network(
                  'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/1.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // 추가 하이라이트 효과
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment(
                    _tiltY / 2,
                    _tiltX / 2,
                  ),
                  end: Alignment(
                    -_tiltY / 2,
                    -_tiltX / 2,
                  ),
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(_glareOpacity * 0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
