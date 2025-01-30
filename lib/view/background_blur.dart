import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pokemon_card/view/pokemon_info_provider.dart';

class BackgroudBlur extends ConsumerWidget {
  const BackgroudBlur({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pokemonInfo = ref.watch(pokemonInfoProvider);

    return pokemonInfo.when(
      data: (pokemon) {
        return Stack(
          fit: StackFit.expand,
          children: [
            SizedBox(
              width: 800,
              height: 800,
              child: ColorFiltered(
                // saturation과 contrast 모두 증가
                colorFilter: const ColorFilter.matrix([
                  2.5, -0.5, -0.5, 0, 0, // Red
                  -0.5, 2.5, -0.5, 0, 0, // Green
                  -0.5, -0.5, 2.5, 0, 0, // Blue
                  0, 0, 0, 1.2, 0, // Alpha
                ]),
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.01),
                        Colors.black.withOpacity(0.05),
                      ],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.multiply,
                  child: Image.network(
                    pokemonInfo.value!.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
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
                      Colors.black.withOpacity(0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
      error: (error, stackTrace) {
        return const Center(
          child: Text('Failed to load pokemon'),
        );
      },
    );
  }
}
