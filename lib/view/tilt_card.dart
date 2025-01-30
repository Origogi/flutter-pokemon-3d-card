import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:math' show pi;

// 메인 TiltCard 위젯
class TiltCard extends HookWidget {
  const TiltCard({super.key});

  @override
  Widget build(BuildContext context) {
    final tiltX = useState(0.0);
    final tiltY = useState(0.0);
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    final tiltXAnimation = useAnimation(
      TweenSequence([
        TweenSequenceItem(
          tween: Tween<double>(begin: tiltX.value, end: 0.0),
          weight: 1.0,
        ),
      ]).animate(animationController),
    );

    final tiltYAnimation = useAnimation(
      TweenSequence([
        TweenSequenceItem(
          tween: Tween<double>(begin: tiltY.value, end: 0.0),
          weight: 1.0,
        ),
      ]).animate(animationController),
    );

    final glareOpacity = useMemoized(
      () => ((tiltX.value.abs() + tiltY.value.abs()) / 20) * 0.35,
      [tiltX.value, tiltY.value],
    );

    final onMouseMove = useCallback((PointerHoverEvent event, BuildContext context) {
      final renderBox = context.findRenderObject() as RenderBox;
      final localPosition = renderBox.globalToLocal(event.position);
      final centerX = renderBox.size.width / 2;
      final centerY = renderBox.size.height / 2;

      tiltX.value = (-(localPosition.dy - centerY) / 20).clamp(-8.0, 8.0);
      tiltY.value = (-(localPosition.dx - centerX) / 20).clamp(-8.0, 8.0);
    }, []);

    final onPointerMove = useCallback((Offset position) {
      tiltX.value = (-(position.dy - 200) / 20).clamp(-8.0, 8.0);
      tiltY.value = (-(position.dx - 125) / 20).clamp(-8.0, 8.0);
    }, []);

    final resetTilt = useCallback(() {
      animationController.forward(from: 0.0).then((_) {
        tiltX.value = 0.0;
        tiltY.value = 0.0;
      });
    }, [animationController]);

    useEffect(() => animationController.dispose, []);

    return Center(
      child: kIsWeb
          ? MouseRegion(
              onHover: (event) => onMouseMove(event, context),
              onExit: (_) => resetTilt(),
              child: TiltCardContent(
                tiltX: animationController.isAnimating ? tiltXAnimation : tiltX.value,
                tiltY: animationController.isAnimating ? tiltYAnimation : tiltY.value,
                glareOpacity: glareOpacity,
              ),
            )
          : GestureDetector(
              onPanStart: (details) => onPointerMove(details.localPosition),
              onPanUpdate: (details) => onPointerMove(details.localPosition),
              onPanEnd: (_) => resetTilt(),
              child: TiltCardContent(
                tiltX: animationController.isAnimating ? tiltXAnimation : tiltX.value,
                tiltY: animationController.isAnimating ? tiltYAnimation : tiltY.value,
                glareOpacity: glareOpacity,
              ),
            ),
    );
  }
}

// 틸트 카드 컨텐츠 위젯
class TiltCardContent extends StatelessWidget {
  final double tiltX;
  final double tiltY;
  final double glareOpacity;

  const TiltCardContent({
    super.key,
    required this.tiltX,
    required this.tiltY,
    required this.glareOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(tiltX * (pi / 180))
        ..rotateY(tiltY * (pi / 180)),
      alignment: FractionalOffset.center,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CardBackground(tiltX: tiltX, tiltY: tiltY, glareOpacity: glareOpacity),
          CardImage(tiltX: tiltX, tiltY: tiltY),
          HighlightEffect(tiltX: tiltX, tiltY: tiltY, glareOpacity: glareOpacity),
        ],
      ),
    );
  }
}

// 카드 배경 위젯
class CardBackground extends StatelessWidget {
  final double tiltX;
  final double tiltY;
  final double glareOpacity;

  const CardBackground({
    super.key,
    required this.tiltX,
    required this.tiltY,
    required this.glareOpacity,
  });

  @override
  Widget build(BuildContext context) {
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
          GlareEffect(tiltX: tiltX, tiltY: tiltY, glareOpacity: glareOpacity),
        ],
      ),
    );
  }
}

// Glare 효과 위젯
class GlareEffect extends StatelessWidget {
  final double tiltX;
  final double tiltY;
  final double glareOpacity;

  const GlareEffect({
    super.key,
    required this.tiltX,
    required this.tiltY,
    required this.glareOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment(-0.5 - tiltY / 8, -0.5 + tiltX / 8),
            end: Alignment(0.5 - tiltY / 8, 0.5 + tiltX / 8),
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
}

// 카드 이미지 위젯
class CardImage extends StatelessWidget {
  final double tiltX;
  final double tiltY;

  const CardImage({
    super.key,
    required this.tiltX,
    required this.tiltY,
  });

  @override
  Widget build(BuildContext context) {
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
}

// 하이라이트 효과 위젯
class HighlightEffect extends StatelessWidget {
  final double tiltX;
  final double tiltY;
  final double glareOpacity;

  const HighlightEffect({
    super.key,
    required this.tiltX,
    required this.tiltY,
    required this.glareOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment(tiltY / 2, tiltX / 2),
            end: Alignment(-tiltY / 2, -tiltX / 2),
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
