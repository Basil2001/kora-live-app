import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:kora/core/network/api_client.dart';
import 'package:kora/features/matches/comments_provider.dart';
import 'package:kora/features/auth/auth_provider.dart';

class FakeApiClient extends ApiClient {
  final Map<String, dynamic> mockResponses = {};
  final List<String> deletedComments = [];
  final List<int> likedComments = [];

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
      message: 'Route not mocked: $path',
    );
  }

  @override
  Future<Response> post(String path, {dynamic data}) async {
    if (mockResponses.containsKey(path)) {
      return Response(
        requestOptions: RequestOptions(path: path),
        data: mockResponses[path],
        statusCode: 200,
      );
    }
    if (path.endsWith('/like')) {
      final parts = path.split('/');
      final commentId = int.parse(parts[parts.length - 2]);
      likedComments.add(commentId);
      return Response(
        requestOptions: RequestOptions(path: path),
        data: {'message': 'Liked!', 'likes_count': 1},
        statusCode: 200,
      );
    }
    if (path.startsWith('/matches/') && path.endsWith('/comments')) {
      return Response(
        requestOptions: RequestOptions(path: path),
        data: {
          'message': 'Comment posted successfully.',
          'comment': {
            'id': 100,
            'user_id': 1,
            'body': data['body'],
            'is_pinned': false,
            'likes_count': 0,
            'created_at': '2026-06-10T10:00:00Z',
            'user': {
              'id': 1,
              'name': 'Test User',
              'avatar_url': null,
            }
          }
        },
        statusCode: 201,
      );
    }
    throw DioException(
      requestOptions: RequestOptions(path: path),
      message: 'Route not mocked: $path',
    );
  }

  @override
  Future<Response> delete(String path, {dynamic data}) async {
    deletedComments.add(path);
    return Response(
      requestOptions: RequestOptions(path: path),
      data: {'message': 'Comment deleted.'},
      statusCode: 200,
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

  test('fetchComments loads list successfully', () async {
    fakeApiClient.mockResponses['/matches/1/comments'] = {
      'comments': [
        {
          'id': 1,
          'user_id': 1,
          'body': 'First comment!',
          'is_pinned': false,
          'likes_count': 5,
          'created_at': '2026-06-10T09:00:00Z',
          'user': {
            'id': 1,
            'name': 'User One',
            'avatar_url': 'https://example.com/avatar1.png'
          }
        }
      ],
      'total': 1,
      'current_page': 1,
      'last_page': 1,
    };

    final notifier = container.read(commentsProvider(1).notifier);
    await notifier.fetchComments();

    final state = container.read(commentsProvider(1));
    expect(state.isLoading, false);
    expect(state.comments.length, 1);
    expect(state.comments[0].body, 'First comment!');
    expect(state.comments[0].likesCount, 5);
    expect(state.comments[0].userName, 'User One');
  });

  test('postComment adds new comment to top of list', () async {
    final notifier = container.read(commentsProvider(1).notifier);
    final success = await notifier.postComment('New live comment');

    expect(success, true);
    final state = container.read(commentsProvider(1));
    expect(state.comments.length, 1);
    expect(state.comments[0].id, 100);
    expect(state.comments[0].body, 'New live comment');
  });

  test('likeComment increments count locally', () async {
    fakeApiClient.mockResponses['/matches/1/comments'] = {
      'comments': [
        {
          'id': 5,
          'user_id': 2,
          'body': 'Pre-existing comment',
          'likes_count': 2,
        }
      ],
      'total': 1,
      'current_page': 1,
      'last_page': 1,
    };

    final notifier = container.read(commentsProvider(1).notifier);
    await notifier.fetchComments();

    expect(container.read(commentsProvider(1)).comments[0].likesCount, 2);

    await notifier.likeComment(5);

    expect(container.read(commentsProvider(1)).comments[0].likesCount, 3);
    expect(fakeApiClient.likedComments.contains(5), true);
  });

  test('deleteComment removes it from list', () async {
    fakeApiClient.mockResponses['/matches/1/comments'] = {
      'comments': [
        {
          'id': 12,
          'user_id': 2,
          'body': 'To be deleted',
          'likes_count': 0,
        }
      ],
      'total': 1,
      'current_page': 1,
      'last_page': 1,
    };

    final notifier = container.read(commentsProvider(1).notifier);
    await notifier.fetchComments();
    expect(container.read(commentsProvider(1)).comments.length, 1);

    await notifier.deleteComment(12);

    expect(container.read(commentsProvider(1)).comments.length, 0);
    expect(fakeApiClient.deletedComments.contains('/matches/1/comments/12'), true);
  });
}
