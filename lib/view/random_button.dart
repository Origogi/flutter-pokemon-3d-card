

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pokemon_card/view/pokemon_info_provider.dart';

class RandomButton extends HookConsumerWidget {
  final borderColor = const Color(0xFFFFC83C);
  final backgroundColor = const Color(0xBF000000);

  const RandomButton({
    super.key,
  });

  

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHovered = useState(false);
    
    // 애니메이션 컨트롤러 hook
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 200),
    );

    // 스케일 애니메이션 hook
    final scaleAnimation = useAnimation(
      Tween<double>(
        begin: 1.0,
        end: 0.95,
      ).animate(
        CurvedAnimation(
          parent: animationController,
          curve: Curves.easeInOut,
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      child: GestureDetector(
        onTapDown: (_) => animationController.forward(),
        onTapUp: (_) => animationController.reverse(),
        onTapCancel: () => animationController.reverse(),
        onTap: () {
          ref.read(pokemonInfoProvider.notifier).fetchRandomPokemon();
        },
        child: Transform.scale(
          scale: scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor,
                width: 5,
              ),
              boxShadow: [
                BoxShadow(
                  color: borderColor.withValues(alpha : isHovered.value ? 0.4 : 0.2),
                  blurRadius: isHovered.value ? 15 : 10,
                  spreadRadius: isHovered.value ? 2 : 1,
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              child: Text(
                "RANDOM",
                style: TextStyle(
                  fontFamily: 'Silkscreen',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
