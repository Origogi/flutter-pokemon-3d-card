import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pokemon_card/data/pokemon_repository.dart';
import 'package:pokemon_card/domain/pokemon_info.dart';

class PokemonInfoNotifier extends AsyncNotifier<PokemonInfo> {
  @override
  Future<PokemonInfo> build() async {
    return await _fetchRandomPokemon();
  }

  Future<PokemonInfo> _fetchRandomPokemon() async {
    final repository = ref.read(pokemonRepositoryProvider);
    return await repository.getRandomPokemon();
  }

  Future<void> fetchRandomPokemon() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _fetchRandomPokemon();
    });
  }
}

final pokemonInfoProvider =
    AsyncNotifierProvider<PokemonInfoNotifier, PokemonInfo>(() {
  return PokemonInfoNotifier();
});
