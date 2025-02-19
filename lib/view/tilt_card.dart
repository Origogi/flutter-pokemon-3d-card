import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pokemon_card/util/platform_checker.dart';
import 'package:pokemon_card/view/pokemon_info_provider.dart';
import 'package:lottie/lottie.dart';

class TiltCard extends HookConsumerWidget {
  const TiltCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // tilt 상태를 useState로 관리
    final tiltX = useState(0.0);
    final tiltY = useState(0.0);

    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    // glareOpacity 계산
    final glareOpacity = useMemoized(
      () => ((tiltX.value.abs() + tiltY.value.abs()) / 20) * 0.35,
      [tiltX.value, tiltY.value],
    );

    // Mouse move handler
    final onMouseMove =
        useCallback((PointerHoverEvent event, BuildContext context) {
      final renderBox = context.findRenderObject() as RenderBox;
      final localPosition = renderBox.globalToLocal(event.position);
      final centerX = renderBox.size.width / 2;
      final centerY = renderBox.size.height / 2;

      tiltX.value = ((localPosition.dy - centerY) / 20).clamp(-8.0, 8.0);
      tiltY.value = (-(localPosition.dx - centerX) / 20).clamp(-8.0, 8.0);
    }, []);

    // Pointer move handler
    final onPointerMove = useCallback((Offset position) {
      tiltX.value = ((position.dy - 200) / 20).clamp(-8.0, 8.0);
      tiltY.value = (-(position.dx - 125) / 20).clamp(-8.0, 8.0);
    }, []);

    // Reset handler
    final resetTilt = useCallback(() async {
      // 애니메이션의 시작값을 현재 틸트 값으로 업데이트
      final newTiltXAnimation = Tween<double>(
        begin: tiltX.value,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOut,
      ));

      final newTiltYAnimation = Tween<double>(
        begin: tiltY.value,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOut,
      ));

      // 애니메이션 리스너 설정
      void updateTilt() {
        tiltX.value = newTiltXAnimation.value;
        tiltY.value = newTiltYAnimation.value;
      }

      newTiltXAnimation.addListener(updateTilt);
      newTiltYAnimation.addListener(updateTilt);

      await animationController.forward(from: 0.0);

      // 리스너 제거
      newTiltXAnimation.removeListener(updateTilt);
      newTiltYAnimation.removeListener(updateTilt);

      // 최종 값 설정
      tiltX.value = 0.0;
      tiltY.value = 0.0;
    }, [animationController]);

    // Cleanup
    useEffect(() {
      return () => animationController.dispose();
    }, []);

    return Center(
        child: PlatformChecker.isMobile
            ? GestureDetector(
                onPanStart: (details) => onPointerMove(details.localPosition),
                onPanUpdate: (details) => onPointerMove(details.localPosition),
                onPanEnd: (_) => resetTilt(),
                child: TiltCardContent(
                  tiltX: tiltX.value,
                  tiltY: tiltY.value,
                  glareOpacity: glareOpacity,
                ),
              )
            : MouseRegion(
                onHover: (event) => onMouseMove(event, context),
                onExit: (_) => resetTilt(),
                child: TiltCardContent(
                  tiltX: tiltX.value,
                  tiltY: tiltY.value,
                  glareOpacity: glareOpacity,
                ),
              ));
  }
}

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
          // 카드 배경
          Container(
            width: 250,
            height: 400,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
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
                // 카드 텍스트 내용
                const Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: PokemonInfoLabels(),
                ),
                // Glare 효과
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        begin: Alignment(
                          -0.5 - tiltY / 8, // tilt에 따라 시작점 이동
                          -0.5 + tiltX / 8,
                        ),
                        end: Alignment(
                          0.5 - tiltY / 8, // tilt에 따라 끝점 이동
                          0.5 + tiltX / 8,
                        ),
                        colors: [
                          Colors.white.withValues(alpha: glareOpacity),
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
                ..rotateX(tiltX * (pi / 180))
                ..rotateY(tiltY * (pi / 180))
                ..translate(0.0, 0.0, -100.0),
              alignment: FractionalOffset.center,
              child: const PokemonImage(),
            ),
          ),
          // 추가 하이라이트 효과
          Positioned.fill(
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
                    Colors.white.withValues(alpha: glareOpacity * 0.2),
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
}

class PokemonImage extends ConsumerWidget {
  const PokemonImage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pokemonInfo = ref.watch(pokemonInfoProvider);

    return pokemonInfo.when(
      data: (pokemon) {
        return SizedBox(
          width: 350,
          height: 350,
          child: Image(
            image: NetworkImage(
              pokemon.imageUrl,
            ),
            fit: BoxFit.contain,
          ),
        );
      },
      loading: () => const Center(
        child: SizedBox.shrink(),
      ),
      error: (error, _) => Text('Error: $error'),
    );
  }
}

class PokemonInfoLabels extends ConsumerWidget {
  const PokemonInfoLabels({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pokemonInfo = ref.watch(pokemonInfoProvider);

    return pokemonInfo.when(
      data: (pokemon) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              pokemon.name,
              style: const TextStyle(
                fontFamily: 'Silkscreen',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${pokemon.hp}HP',
              style: const TextStyle(
                fontFamily: 'Silkscreen',
                fontSize: 16,
                color: Color(0xFFFFC83C),
              ),
            ),
          ],
        );
      },
      loading: () => Center(
        child: Image.asset(
          "assets/gif/loading.gif",
          width: 150,
          height: 150,
          fit: BoxFit.contain,
        ),
      ),
      error: (error, _) => Text('Error: $error'),
    );
  }
}
