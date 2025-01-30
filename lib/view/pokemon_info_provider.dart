import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pokemon_card/data/pokemon_repository.dart';
import 'package:pokemon_card/domain/pokemon_info.dart';

class PokemonInfoNotifier extends StateNotifier<AsyncValue<PokemonInfo>> {
  final PokemonRepository _repository;

  PokemonInfoNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchRandomPokemon();
  }

  Future<void> fetchRandomPokemon() async {
    try {
      state = const AsyncValue.loading();
      final pokemon = await _repository.getRandomPokemon();
      state = AsyncValue.data(pokemon);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final pokemonInfoProvider =
    StateNotifierProvider<PokemonInfoNotifier, AsyncValue<PokemonInfo>>((ref) {
  final repository = ref.watch(pokemonRepositoryProvider);
  return PokemonInfoNotifier(repository);
});
