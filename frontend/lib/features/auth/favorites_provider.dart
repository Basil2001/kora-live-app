import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../auth/auth_provider.dart';

class FavoritesNotifier extends StateNotifier<AsyncValue<Set<int>>> {
  final ApiClient _apiClient;
  final Ref _ref;

  FavoritesNotifier(this._apiClient, this._ref) : super(const AsyncValue.data({})) {
    _ref.listen(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        fetchFavorites();
      } else {
        state = const AsyncValue.data({});
      }
    });
    
    final authState = _ref.read(authProvider);
    if (authState.isAuthenticated) {
      fetchFavorites();
    }
  }

  Future<void> fetchFavorites() async {
    try {
      final response = await _apiClient.get('/favorites');
      final List<dynamic> data = response.data;
      final favoriteIds = data.map<int>((e) => e['id'] as int).toSet();
      state = AsyncValue.data(favoriteIds);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> toggleFavorite(int teamId) async {
    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated) {
      return false;
    }

    final currentSet = state.value ?? {};
    final isFavorited = currentSet.contains(teamId);
    
    final newSet = Set<int>.from(currentSet);
    if (isFavorited) {
      newSet.remove(teamId);
    } else {
      newSet.add(teamId);
    }
    state = AsyncValue.data(newSet);

    try {
      final response = await _apiClient.post('/favorites/toggle', data: {'team_id': teamId});
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      state = AsyncValue.data(currentSet);
    }
    return false;
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, AsyncValue<Set<int>>>((ref) {
  final client = ref.watch(apiClientProvider);
  return FavoritesNotifier(client, ref);
});
