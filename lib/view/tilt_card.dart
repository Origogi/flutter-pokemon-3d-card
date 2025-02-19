import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pokemon_card/domain/pokemon_info.dart';
import 'package:pokemon_card/util/platform_checker.dart';
import 'package:pokemon_card/view/pokemon_info_provider.dart';

const double _cardWidth = 250.0;
const double _cardHeight = 400.0;
const double _imageSize = 350.0;
const double _loadingGifSize = 150.0;

class TiltCard extends HookConsumerWidget {
  const TiltCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiltX = useState(0.0);
    final tiltY = useState(0.0);
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    final glareOpacity = useMemoized(
      () => ((tiltX.value.abs() + tiltY.value.abs()) / 20) * 0.35,
      [tiltX.value, tiltY.value],
    );

    final onPointerMove =
        useCallback((Offset position, {bool isMobile = false}) {
      final centerX = isMobile ? 125.0 : _cardWidth / 2;
      final centerY = isMobile ? 200.0 : _cardHeight / 2;
      tiltX.value = ((position.dy - centerY) / 20).clamp(-8.0, 8.0);
      tiltY.value = (-(position.dx - centerX) / 20).clamp(-8.0, 8.0);
    }, []);

    final resetTilt = useCallback(() async {
      final animations = [
        Tween<double>(begin: tiltX.value, end: 0.0),
        Tween<double>(begin: tiltY.value, end: 0.0),
      ].map((tween) => tween.animate(
            CurvedAnimation(
              parent: animationController,
              curve: Curves.easeOut,
            ),
          ));

      void updateTilt() {
        tiltX.value = animations.first.value;
        tiltY.value = animations.last.value;
      }

      for (var animation in animations) {
        animation.addListener(updateTilt);
      }
      await animationController.forward(from: 0.0);
      for (var animation in animations) {
        animation.removeListener(updateTilt);
      }

      tiltX.value = 0.0;
      tiltY.value = 0.0;
    }, [animationController]);

    useEffect(() => animationController.dispose, []);

    return Center(
      child: PlatformChecker.isMobile
          ? GestureDetector(
              onPanStart: (details) =>
                  onPointerMove(details.localPosition, isMobile: true),
              onPanUpdate: (details) =>
                  onPointerMove(details.localPosition, isMobile: true),
              onPanEnd: (_) => resetTilt(),
              child:
                  _buildTiltCardContent(tiltX.value, tiltY.value, glareOpacity),
            )
          : MouseRegion(
              onHover: (event) {
                final renderBox = context.findRenderObject() as RenderBox;
                onPointerMove(renderBox.globalToLocal(event.position));
              },
              onExit: (_) => resetTilt(),
              child:
                  _buildTiltCardContent(tiltX.value, tiltY.value, glareOpacity),
            ),
    );
  }

  Widget _buildTiltCardContent(
      double tiltX, double tiltY, double glareOpacity) {
    return TiltCardContent(
      tiltX: tiltX,
      tiltY: tiltY,
      glareOpacity: glareOpacity,
    );
  }
}

class TiltCardContent extends ConsumerWidget {
  final double tiltX;
  final double tiltY;
  final double glareOpacity;

  const TiltCardContent({
    super.key,
    required this.tiltX,
    required this.tiltY,
    required this.glareOpacity,
  });

  Matrix4 _buildTransformMatrix(double tiltX, double tiltY) {
    return Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateX(tiltX * (pi / 180))
      ..rotateY(tiltY * (pi / 180));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pokemonInfo = ref.watch(pokemonInfoProvider);

    return Transform(
      transform: _buildTransformMatrix(tiltX, tiltY),
      alignment: FractionalOffset.center,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildCardContainer(pokemonInfo),
          _buildPokemonImageContainer(),
          _buildGlareEffect(),
        ],
      ),
    );
  }

  Widget _buildCardContainer(AsyncValue<PokemonInfo> pokemonInfo) {
    return Container(
      width: _cardWidth,
      height: _cardHeight,
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
      child: pokemonInfo.when(
        data: (pokemon) => _buildPokemonInfo(pokemon),
        loading: () => const SizedBox.shrink(),
        error: (error, _) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildPokemonInfo(PokemonInfo pokemon) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Column(
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
          ),
        ),
        _buildInnerGlareEffect(),
      ],
    );
  }

  Widget _buildPokemonImageContainer() {
    return Positioned(
      bottom: -20,
      left: 0,
      right: 0,
      child: Transform(
        transform: _buildTransformMatrix(tiltX, tiltY)
          ..translate(0.0, 0.0, -100.0),
        alignment: FractionalOffset.center,
        child: const SizedBox(
          width: _imageSize,
          height: _imageSize,
          child: PokemonImage(),
        ),
      ),
    );
  }

  Widget _buildGlareEffect() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
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

  Widget _buildInnerGlareEffect() {
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

class PokemonImage extends ConsumerStatefulWidget {
  const PokemonImage({super.key});

  @override
  ConsumerState<PokemonImage> createState() => _PokemonImageState();
}

class _PokemonImageState extends ConsumerState<PokemonImage> {
  bool isImageLoaded = false;
  ImageProvider? _imageProvider;

  void _handlePokemonInfo(PokemonInfo? pokemon) {
    if (pokemon == null) return;

    setState(() => isImageLoaded = false);

    _imageProvider = NetworkImage(pokemon.imageUrl);
    _imageProvider!.resolve(const ImageConfiguration()).addListener(
          ImageStreamListener(
            (ImageInfo image, bool synchronousCall) {
              if (mounted) setState(() => isImageLoaded = true);
            },
            onError: (dynamic exception, StackTrace? stackTrace) {
              if (mounted) setState(() => isImageLoaded = false);
            },
          ),
        );
  }

  Widget _buildLoadingImage() {
    return SizedBox(
      width: _imageSize,
      height: _imageSize,
      child: Center(
        child: Image.asset(
          "assets/gif/loading.gif",
          width: _loadingGifSize,
          height: _loadingGifSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pokemonInfo = ref.watch(pokemonInfoProvider);

    ref.listen(pokemonInfoProvider, (previous, next) {
      next.whenData(_handlePokemonInfo);
    });

    return pokemonInfo.when(
      data: (pokemon) => isImageLoaded
          ? SizedBox(
              width: _imageSize,
              height: _imageSize,
              child: Image(
                image: _imageProvider!,
                fit: BoxFit.contain,
              ),
            )
          : _buildLoadingImage(),
      loading: () => _buildLoadingImage(),
      error: (error, _) => const SizedBox(
        width: _imageSize,
        height: _imageSize,
        child: Center(
          child: Text('Error loading image'),
        ),
      ),
    );
  }
}
