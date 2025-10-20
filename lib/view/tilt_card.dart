import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pokemon_card/util/platform_checker.dart';
import 'package:pokemon_card/view/pokemon_info_provider.dart';

// ============================================================================
// Constants
// ============================================================================

/// 틸트 애니메이션 관련 상수
class TiltConstants {
  TiltConstants._();

  /// 틸트 보간 계수 (0.0 ~ 1.0, 값이 클수록 목표값에 빠르게 도달)
  static const double smoothingFactor = 0.2;

  /// 틸트 최대 각도 (degrees)
  static const double maxTiltAngle = 8.0;

  /// 틸트 계산 민감도 조절 값
  static const double sensitivityDivisor = 20.0;

  /// 리셋 애니메이션 지속 시간
  static const Duration resetAnimationDuration = Duration(milliseconds: 300);

  /// Glare 효과 강도 계수
  static const double glareIntensityFactor = 0.35;
  static const double glareIntensityDivisor = 20.0;
}

/// 모바일 터치 입력 관련 상수
class MobileTouchConstants {
  MobileTouchConstants._();

  /// 터치 중심점 Y 좌표 (추정값)
  static const double centerY = 200.0;

  /// 터치 중심점 X 좌표 (추정값)
  static const double centerX = 125.0;
}

/// 카드 시각적 요소 관련 상수
class CardVisualConstants {
  CardVisualConstants._();

  /// 카드 너비
  static const double width = 250.0;

  /// 카드 높이
  static const double height = 400.0;

  /// 카드 모서리 둥글기
  static const double borderRadius = 20.0;

  /// 카드 테두리 두께
  static const double borderWidth = 10.0;

  /// 카드 테두리 색상
  static const Color borderColor = Color(0xFFFFC83C);

  /// 카드 배경 투명도
  static const double backgroundAlpha = 0.75;

  /// 그림자 흐림 반경
  static const double shadowBlurRadius = 200.0;

  /// 그림자 오프셋
  static const Offset shadowOffset = Offset(0, 50);

  /// 그림자 확산 반경
  static const double shadowSpreadRadius = -25.0;
}

/// 포켓몬 이미지 관련 상수
class PokemonImageConstants {
  PokemonImageConstants._();

  /// 이미지 표시 크기
  static const double displaySize = 350.0;

  /// 이미지 캐시 크기 (메모리 최적화)
  static const int cacheSize = 700;

  /// 이미지 필터 품질
  static const FilterQuality filterQuality = FilterQuality.medium;

  /// 이미지 Z축 오프셋
  static const double zOffset = -100.0;

  /// 이미지 하단 위치 오프셋
  static const double bottomOffset = -20.0;
}

/// 3D 변환 관련 상수
class Transform3DConstants {
  Transform3DConstants._();

  /// 각도를 라디안으로 변환하는 계수
  static const double degToRad = pi / 180;

  /// 원근 효과 강도
  static const double perspective = 0.001;
}

// ============================================================================
// Tilt Calculation Utilities
// ============================================================================

/// 틸트 계산 유틸리티 클래스
class TiltCalculator {
  TiltCalculator._();

  /// 마우스/터치 위치를 기반으로 틸트 값 계산
  ///
  /// [position]: 현재 입력 위치
  /// [center]: 중심점
  /// [isX]: X축 계산 여부 (false면 Y축)
  static double calculateTiltAngle({
    required double position,
    required double center,
    required bool isX,
  }) {
    final offset = position - center;
    final tiltValue = offset / TiltConstants.sensitivityDivisor;
    final clamped = tiltValue.clamp(
      -TiltConstants.maxTiltAngle,
      TiltConstants.maxTiltAngle,
    );

    // Y축은 반전 (위로 올리면 음수)
    return isX ? -clamped : clamped;
  }

  /// 현재 틸트 값을 목표 값으로 부드럽게 보간
  static double interpolateTilt({
    required double current,
    required double target,
  }) {
    return lerpDouble(
      current,
      target,
      TiltConstants.smoothingFactor,
    )!;
  }

  /// Glare 효과 투명도 계산
  static double calculateGlareOpacity({
    required double tiltX,
    required double tiltY,
  }) {
    return ((tiltX.abs() + tiltY.abs()) /
            TiltConstants.glareIntensityDivisor) *
        TiltConstants.glareIntensityFactor;
  }
}

// ============================================================================
// Main Widget
// ============================================================================

/// 3D 틸트 효과를 가진 포켓몬 카드 위젯
///
/// 마우스 호버 또는 터치 제스처로 카드를 3D 회전시킬 수 있습니다.
/// 플랫폼에 따라 자동으로 입력 방식이 전환됩니다.
class TiltCard extends HookConsumerWidget {
  const TiltCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 상태 관리
    final tiltX = useState(0.0);
    final tiltY = useState(0.0);
    final animationController = useAnimationController(
      duration: TiltConstants.resetAnimationDuration,
    );

    // Glare 효과 계산 (메모이제이션)
    final glareOpacity = useMemoized(
      () => TiltCalculator.calculateGlareOpacity(
        tiltX: tiltX.value,
        tiltY: tiltY.value,
      ),
      [tiltX.value, tiltY.value],
    );

    // 이벤트 핸들러
    final handlers = _TiltEventHandlers(
      tiltX: tiltX,
      tiltY: tiltY,
      animationController: animationController,
    );

    // 애니메이션 컨트롤러 정리
    useEffect(() {
      return animationController.dispose;
    }, []);

    return Center(
      child: PlatformChecker.isMobile
          ? _buildMobileGestureDetector(handlers, tiltX, tiltY, glareOpacity)
          : _buildDesktopMouseRegion(
              context, handlers, tiltX, tiltY, glareOpacity),
    );
  }

  /// 모바일용 제스처 감지기 생성
  Widget _buildMobileGestureDetector(
    _TiltEventHandlers handlers,
    ValueNotifier<double> tiltX,
    ValueNotifier<double> tiltY,
    double glareOpacity,
  ) {
    return GestureDetector(
      onPanStart: (details) => handlers.onMobileTouch(details.localPosition),
      onPanUpdate: (details) => handlers.onMobileTouch(details.localPosition),
      onPanEnd: (_) => handlers.onInputEnd(),
      child: TiltCardContent(
        tiltX: tiltX.value,
        tiltY: tiltY.value,
        glareOpacity: glareOpacity,
      ),
    );
  }

  /// 데스크톱용 마우스 리전 생성
  Widget _buildDesktopMouseRegion(
    BuildContext context,
    _TiltEventHandlers handlers,
    ValueNotifier<double> tiltX,
    ValueNotifier<double> tiltY,
    double glareOpacity,
  ) {
    return MouseRegion(
      onHover: (event) => handlers.onMouseHover(event, context),
      onExit: (_) => handlers.onInputEnd(),
      child: TiltCardContent(
        tiltX: tiltX.value,
        tiltY: tiltY.value,
        glareOpacity: glareOpacity,
      ),
    );
  }
}

// ============================================================================
// Event Handlers
// ============================================================================

/// 틸트 입력 이벤트 핸들러
///
/// Single Responsibility: 입력 이벤트 처리만 담당
class _TiltEventHandlers {
  _TiltEventHandlers({
    required this.tiltX,
    required this.tiltY,
    required this.animationController,
  });

  final ValueNotifier<double> tiltX;
  final ValueNotifier<double> tiltY;
  final AnimationController animationController;

  /// 마우스 호버 이벤트 처리
  void onMouseHover(PointerHoverEvent event, BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(event.position);
    final centerX = renderBox.size.width / 2;
    final centerY = renderBox.size.height / 2;

    _updateTiltValues(
      localX: localPosition.dx,
      localY: localPosition.dy,
      centerX: centerX,
      centerY: centerY,
    );
  }

  /// 모바일 터치 이벤트 처리
  void onMobileTouch(Offset position) {
    _updateTiltValues(
      localX: position.dx,
      localY: position.dy,
      centerX: MobileTouchConstants.centerX,
      centerY: MobileTouchConstants.centerY,
    );
  }

  /// 입력 종료 시 틸트 리셋
  Future<void> onInputEnd() async {
    final tiltXAnimation = Tween<double>(
      begin: tiltX.value,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    ));

    final tiltYAnimation = Tween<double>(
      begin: tiltY.value,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    ));

    void updateTilt() {
      tiltX.value = tiltXAnimation.value;
      tiltY.value = tiltYAnimation.value;
    }

    tiltXAnimation.addListener(updateTilt);
    tiltYAnimation.addListener(updateTilt);

    await animationController.forward(from: 0.0);

    tiltXAnimation.removeListener(updateTilt);
    tiltYAnimation.removeListener(updateTilt);

    tiltX.value = 0.0;
    tiltY.value = 0.0;
  }

  /// 틸트 값 업데이트 (내부 헬퍼 메서드)
  void _updateTiltValues({
    required double localX,
    required double localY,
    required double centerX,
    required double centerY,
  }) {
    final targetX = TiltCalculator.calculateTiltAngle(
      position: localY,
      center: centerY,
      isX: true,
    );

    final targetY = TiltCalculator.calculateTiltAngle(
      position: localX,
      center: centerX,
      isX: false,
    );

    tiltX.value = TiltCalculator.interpolateTilt(
      current: tiltX.value,
      target: targetX,
    );

    tiltY.value = TiltCalculator.interpolateTilt(
      current: tiltY.value,
      target: targetY,
    );
  }
}

// ============================================================================
// Card Content Widget
// ============================================================================

/// 틸트 카드의 시각적 콘텐츠
///
/// Single Responsibility: 카드의 시각적 표현만 담당
class TiltCardContent extends StatelessWidget {
  const TiltCardContent({
    super.key,
    required this.tiltX,
    required this.tiltY,
    required this.glareOpacity,
  });

  final double tiltX;
  final double tiltY;
  final double glareOpacity;

  @override
  Widget build(BuildContext context) {
    final radX = tiltX * Transform3DConstants.degToRad;
    final radY = tiltY * Transform3DConstants.degToRad;

    return RepaintBoundary(
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, Transform3DConstants.perspective)
          ..rotateX(radX)
          ..rotateY(radY),
        alignment: FractionalOffset.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _CardBackground(tiltX: tiltX, tiltY: tiltY, glareOpacity: glareOpacity),
            _PokemonImageLayer(radX: radX, radY: radY),
            _HighlightEffect(tiltX: tiltX, tiltY: tiltY, glareOpacity: glareOpacity),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Card Visual Layers
// ============================================================================

/// 카드 배경 레이어
class _CardBackground extends StatelessWidget {
  const _CardBackground({
    required this.tiltX,
    required this.tiltY,
    required this.glareOpacity,
  });

  final double tiltX;
  final double tiltY;
  final double glareOpacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: CardVisualConstants.width,
      height: CardVisualConstants.height,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: CardVisualConstants.backgroundAlpha),
        borderRadius: BorderRadius.circular(CardVisualConstants.borderRadius),
        border: Border.all(
          color: CardVisualConstants.borderColor,
          width: CardVisualConstants.borderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: CardVisualConstants.shadowBlurRadius,
            offset: CardVisualConstants.shadowOffset,
            spreadRadius: CardVisualConstants.shadowSpreadRadius,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: PokemonInfoLabels(),
          ),
          _GlareEffect(tiltX: tiltX, tiltY: tiltY, glareOpacity: glareOpacity),
        ],
      ),
    );
  }
}

/// Glare(빛 반사) 효과 레이어
class _GlareEffect extends StatelessWidget {
  const _GlareEffect({
    required this.tiltX,
    required this.tiltY,
    required this.glareOpacity,
  });

  final double tiltX;
  final double tiltY;
  final double glareOpacity;

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
              Colors.white.withValues(alpha: glareOpacity),
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

/// 포켓몬 이미지 레이어
class _PokemonImageLayer extends StatelessWidget {
  const _PokemonImageLayer({
    required this.radX,
    required this.radY,
  });

  final double radX;
  final double radY;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: PokemonImageConstants.bottomOffset,
      left: 0,
      right: 0,
      child: RepaintBoundary(
        child: Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, Transform3DConstants.perspective)
            ..rotateX(radX)
            ..rotateY(radY)
            ..setTranslationRaw(0.0, 0.0, PokemonImageConstants.zOffset),
          alignment: FractionalOffset.center,
          child: const PokemonImage(),
        ),
      ),
    );
  }
}

/// 하이라이트 효과 레이어
class _HighlightEffect extends StatelessWidget {
  const _HighlightEffect({
    required this.tiltX,
    required this.tiltY,
    required this.glareOpacity,
  });

  final double tiltX;
  final double tiltY;
  final double glareOpacity;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(CardVisualConstants.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(tiltY / 2, tiltX / 2),
            end: Alignment(-tiltY / 2, -tiltX / 2),
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: glareOpacity * 0.2),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Pokemon Data Widgets
// ============================================================================

/// 포켓몬 이미지 위젯
class PokemonImage extends ConsumerWidget {
  const PokemonImage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pokemonInfo = ref.watch(pokemonInfoProvider);

    return pokemonInfo.when(
      data: (pokemon) => SizedBox(
        width: PokemonImageConstants.displaySize,
        height: PokemonImageConstants.displaySize,
        child: Image.network(
          pokemon.imageUrl,
          fit: BoxFit.contain,
          cacheWidth: PokemonImageConstants.cacheSize,
          cacheHeight: PokemonImageConstants.cacheSize,
          filterQuality: PokemonImageConstants.filterQuality,
        ),
      ),
      loading: () => const Center(child: SizedBox.shrink()),
      error: (error, _) => Text('Error: $error'),
    );
  }
}

/// 포켓몬 정보 라벨 (이름, HP)
class PokemonInfoLabels extends ConsumerWidget {
  const PokemonInfoLabels({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pokemonInfo = ref.watch(pokemonInfoProvider);

    return pokemonInfo.when(
      data: (pokemon) => Column(
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
              color: CardVisualConstants.borderColor,
            ),
          ),
        ],
      ),
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
