import 'dart:ui';
import 'package:flutter/material.dart';

class BackgroudBlur extends StatelessWidget {
  const BackgroudBlur({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/1.png',
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
  }
}
