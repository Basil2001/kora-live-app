import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:kora/core/network/api_client.dart';
import 'package:kora/features/auth/auth_provider.dart';

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
      if (responseData is Map && responseData.containsKey('status_code')) {
        final code = responseData['status_code'] as int;
        if (code >= 400) {
          throw DioException(
            requestOptions: RequestOptions(path: path),
            response: Response(
              requestOptions: RequestOptions(path: path),
              statusCode: code,
              data: responseData,
            ),
          );
        }
      }
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

  test('initial state is unauthenticated', () {
    final state = container.read(authProvider);
    expect(state.isAuthenticated, false);
    expect(state.name, null);
    expect(state.email, null);
    expect(state.token, null);
  });

  test('login success updates state', () async {
    fakeApiClient.mockResponses['/auth/login'] = {
      'access_token': 'my-secret-token',
      'token_type': 'Bearer',
      'user': {
        'id': 1,
        'name': 'John Doe',
        'email': 'john@example.com',
      }
    };

    final result = await container.read(authProvider.notifier).login('john@example.com', 'password123');

    expect(result, true);
    final state = container.read(authProvider);
    expect(state.isAuthenticated, true);
    expect(state.name, 'John Doe');
    expect(state.email, 'john@example.com');
    expect(state.token, 'my-secret-token');
    expect(fakeApiClient.lastToken, 'my-secret-token');
  });

  test('login failure keeps state unauthenticated', () async {
    fakeApiClient.mockResponses['/auth/login'] = {
      'status_code': 401,
      'message': 'Invalid credentials',
    };

    final result = await container.read(authProvider.notifier).login('john@example.com', 'wrongpassword');

    expect(result, false);
    final state = container.read(authProvider);
    expect(state.isAuthenticated, false);
    expect(state.token, null);
    expect(fakeApiClient.lastToken, null);
  });

  test('logout clears user session', () async {
    // login first
    fakeApiClient.mockResponses['/auth/login'] = {
      'access_token': 'my-secret-token',
      'token_type': 'Bearer',
      'user': {
        'id': 1,
        'name': 'John Doe',
        'email': 'john@example.com',
      }
    };
    await container.read(authProvider.notifier).login('john@example.com', 'password123');

    // logout
    await container.read(authProvider.notifier).logout();

    final state = container.read(authProvider);
    expect(state.isAuthenticated, false);
    expect(state.token, null);
    expect(fakeApiClient.lastToken, null);
  });
}
