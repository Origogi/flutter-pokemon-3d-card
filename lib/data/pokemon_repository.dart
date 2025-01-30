import 'dart:convert';
import 'dart:math';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:pokemon_card/domain/pokemon_info.dart';

class PokemonRepository {
  static const String baseUrl = 'https://pokeapi.co/api/v2/pokemon/';
  static const int pokemonCount = 151;

  Future<PokemonInfo> getRandomPokemon() async {
    final id = Random().nextInt(pokemonCount) + 1;
    
    try {
      final response = await http.get(Uri.parse('$baseUrl$id'));
      if (response.statusCode == 200) {
        final pokemonData = json.decode(response.body);
        return PokemonInfo.fromJson(pokemonData);
      } else {
        throw Exception('Failed to load pokemon');
      }
    } catch (e) {
      throw Exception('Failed to load pokemon');
    }
  }
}

final pokemonRepositoryProvider = Provider((ref) => PokemonRepository());
