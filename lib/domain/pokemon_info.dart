class PokemonInfo {
  final String name;
  final String imageUrl;
  final int hp;  // stats[0].base_stat

  PokemonInfo({
    required this.name,
    required this.imageUrl,
    required this.hp,
  });

  factory PokemonInfo.fromJson(Map<String, dynamic> json) {
    return PokemonInfo(
      name: json['name'][0].toUpperCase() + json['name'].substring(1),
      imageUrl: json['sprites']['other']['official-artwork']['front_default'],
      hp: json['stats'][0]['base_stat'],
    );
  }
}