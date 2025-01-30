import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:math' show pi;

class TiltCard extends HookWidget {
  const TiltCard({super.key});

  @override
  Widget build(BuildContext context) {
    // tilt 상태 관리
    final tiltX = useState(0.0);
    final tiltY = useState(0.0);

    // 애니메이션 컨트롤러
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    // tilt 애니메이션
    final tiltXAnimation = useAnimation(
      TweenSequence([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: tiltX.value,
            end: 0.0,
          ),
          weight: 1.0,
        ),
      ]).animate(animationController),
    );

    final tiltYAnimation = useAnimation(
      TweenSequence([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: tiltY.value,
            end: 0.0,
          ),
          weight: 1.0,
        ),
      ]).animate(animationController),
    );

    // glare 효과를 위한 opacity 계산
    final glareOpacity = useMemoized(
      () => ((tiltX.value.abs() + tiltY.value.abs()) / 20) * 0.35,
      [tiltX.value, tiltY.value],
    );

    // 마우스 이벤트 핸들러
    final onMouseMove = useCallback((PointerHoverEvent event, BuildContext context) {
      final renderBox = context.findRenderObject() as RenderBox;
      final localPosition = renderBox.globalToLocal(event.position);
      final centerX = renderBox.size.width / 2;
      final centerY = renderBox.size.height / 2;

      tiltX.value = (-(localPosition.dy - centerY) / 20).clamp(-8.0, 8.0);
      tiltY.value = (-(localPosition.dx - centerX) / 20).clamp(-8.0, 8.0);
    }, []);

    // 터치 이벤트 핸들러
    final onPointerMove = useCallback((Offset position) {
      tiltX.value = (-(position.dy - 200) / 20).clamp(-8.0, 8.0);
      tiltY.value = (-(position.dx - 125) / 20).clamp(-8.0, 8.0);
    }, []);

    // 리셋 핸들러
    final resetTilt = useCallback(() {
      animationController.forward(from: 0.0).then((_) {
        tiltX.value = 0.0;
        tiltY.value = 0.0;
      });
    }, [animationController]);

    // 컨트롤러 dispose
    useEffect(() => animationController.dispose, []);

    return Center(
      child: kIsWeb
          ? MouseRegion(
              onHover: (event) => onMouseMove(event, context),
              onExit: (_) => resetTilt(),
              child: _buildTiltCard(
                tiltX: animationController.isAnimating ? tiltXAnimation : tiltX.value,
                tiltY: animationController.isAnimating ? tiltYAnimation : tiltY.value,
                glareOpacity: glareOpacity,
              ),
            )
          : GestureDetector(
              onPanStart: (details) => onPointerMove(details.localPosition),
              onPanUpdate: (details) => onPointerMove(details.localPosition),
              onPanEnd: (_) => resetTilt(),
              child: _buildTiltCard(
                tiltX: animationController.isAnimating ? tiltXAnimation : tiltX.value,
                tiltY: animationController.isAnimating ? tiltYAnimation : tiltY.value,
                glareOpacity: glareOpacity,
              ),
            ),
    );
  }

  Widget _buildTiltCard({
    required double tiltX,
    required double tiltY,
    required double glareOpacity,
  }) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(tiltX * (pi / 180))
        ..rotateY(tiltY * (pi / 180)),
      alignment: FractionalOffset.center,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildCardBackground(tiltX: tiltX, tiltY: tiltY, glareOpacity: glareOpacity),
          _buildCardImage(tiltX: tiltX, tiltY: tiltY),
          _buildHighlightEffect(tiltX: tiltX, tiltY: tiltY, glareOpacity: glareOpacity),
        ],
      ),
    );
  }

  Widget _buildCardBackground({
    required double tiltX,
    required double tiltY,
    required double glareOpacity,
  }) {
    return Container(
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
          const _CardContent(),
          _buildGlareEffect(tiltX: tiltX, tiltY: tiltY, glareOpacity: glareOpacity),
        ],
      ),
    );
  }

  Widget _buildGlareEffect({
    required double tiltX,
    required double tiltY,
    required double glareOpacity,
  }) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment(
              -0.5 - tiltY / 8,
              -0.5 + tiltX / 8,
            ),
            end: Alignment(
              0.5 - tiltY / 8,
              0.5 + tiltX / 8,
            ),
            colors: [
              Colors.white.withOpacity(glareOpacity),
              Colors.transparent,
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildCardImage({
    required double tiltX,
    required double tiltY,
  }) {
    return Positioned(
      bottom: -20,
      left: 0,
      right: 0,
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(tiltX * (pi / 180))
          ..rotateY(tiltY * (pi / 180))
          ..translate(0.0, 0.0, -100.0),
        alignment: FractionalOffset.center,
        child: const SizedBox(
          width: 350,
          height: 350,
          child: Image(
            image: NetworkImage(
              'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/1.png',
            ),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightEffect({
    required double tiltX,
    required double tiltY,
    required double glareOpacity,
  }) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment(
              tiltY / 2,
              tiltX / 2,
            ),
            end: Alignment(
              -tiltY / 2,
              -tiltX / 2,
            ),
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(glareOpacity * 0.2),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent();

  @override
  Widget build(BuildContext context) {
    return const Padding(
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
    );
  }
}
