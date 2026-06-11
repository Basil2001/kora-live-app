import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:kora/core/network/api_client.dart';
import 'package:kora/features/auth/auth_provider.dart';
import 'package:kora/features/auth/favorites_provider.dart';

class FakeApiClient extends ApiClient {
  final Map<String, dynamic> mockResponses = {};
  String? lastToken;

  @override
  void setToken(String? token) {
    lastToken = token;
  }

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    if (mockResponses.containsKey(path)) {
      return Response(
        requestOptions: RequestOptions(path: path),
        data: mockResponses[path],
        statusCode: 200,
      );
    }
    throw DioException(
      requestOptions: RequestOptions(path: path),
      message: 'Route not mocked',
    );
  }

  @override
  Future<Response> post(String path, {dynamic data}) async {
    if (mockResponses.containsKey(path)) {
      final responseData = mockResponses[path];
      return Response(
        requestOptions: RequestOptions(path: path),
        data: responseData,
        statusCode: 200,
      );
    }
    throw DioException(
      requestOptions: RequestOptions(path: path),
      message: 'Route not mocked',
    );
  }
}

void main() {
  late FakeApiClient fakeApiClient;
  late ProviderContainer container;

  setUp(() {
    fakeApiClient = FakeApiClient();
    container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(fakeApiClient),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('initial state has empty favorites', () {
    final state = container.read(favoritesProvider);
    expect(state.value, <int>{});
  });

  test('toggleFavorite returns false when user is not authenticated', () async {
    final result = await container.read(favoritesProvider.notifier).toggleFavorite(5);
    expect(result, false);
    expect(container.read(favoritesProvider).value, <int>{});
  });

  test('fetchFavorites updates state with list from API', () async {
    // Authenticate first
    fakeApiClient.mockResponses['/auth/login'] = {
      'access_token': 'my-token',
      'user': {'id': 1, 'name': 'John'}
    };
    await container.read(authProvider.notifier).login('john@example.com', 'password');

    fakeApiClient.mockResponses['/favorites'] = [
      {'id': 10, 'name': 'Al Ahly SC'},
      {'id': 12, 'name': 'Zamalek SC'},
    ];

    await container.read(favoritesProvider.notifier).fetchFavorites();

    final state = container.read(favoritesProvider);
    expect(state.value, {10, 12});
  });

  test('toggleFavorite attaches and detaches team correctly', () async {
    // Authenticate
    fakeApiClient.mockResponses['/auth/login'] = {
      'access_token': 'my-token',
      'user': {'id': 1, 'name': 'John'}
    };
    await container.read(authProvider.notifier).login('john@example.com', 'password');

    fakeApiClient.mockResponses['/favorites'] = [];
    await container.read(favoritesProvider.notifier).fetchFavorites();

    // Toggle ON
    fakeApiClient.mockResponses['/favorites/toggle'] = {
      'status': 'success',
      'action': 'attached',
      'team_id': 15,
    };

    final addResult = await container.read(favoritesProvider.notifier).toggleFavorite(15);
    expect(addResult, true);
    expect(container.read(favoritesProvider).value, {15});

    // Toggle OFF
    fakeApiClient.mockResponses['/favorites/toggle'] = {
      'status': 'success',
      'action': 'detached',
      'team_id': 15,
    };

    final removeResult = await container.read(favoritesProvider.notifier).toggleFavorite(15);
    expect(removeResult, true);
    expect(container.read(favoritesProvider).value, <int>{});
  });
}
