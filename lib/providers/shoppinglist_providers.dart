import 'package:flutter_riverpod/flutter_riverpod.dart';

final shoppingListProvider = StateProvider<List<String>>((ref) => []);