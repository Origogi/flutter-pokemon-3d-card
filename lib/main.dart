import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pokemon_card/view/home.dart';

void main() {
  runApp(const ProviderScope(child: Home()));
}
  