import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../auth/auth_provider.dart';

class CommentModel {
  final int id;
  final int userId;
  final String userName;
  final String? userAvatar;
  final String body;
  final bool isPinned;
  final int likesCount;
  final String createdAt;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.body,
    required this.isPinned,
    required this.likesCount,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? json['user']?['id'] ?? 0,
      userName: json['user']?['name'] ?? 'Unknown',
      userAvatar: json['user']?['avatar_url'],
      body: json['body'] ?? '',
      isPinned: json['is_pinned'] ?? false,
      likesCount: json['likes_count'] ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }

  CommentModel copyWith({int? likesCount}) {
    return CommentModel(
      id: id,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      body: body,
      isPinned: isPinned,
      likesCount: likesCount ?? this.likesCount,
      createdAt: createdAt,
    );
  }
}

class CommentsState {
  final List<CommentModel> comments;
  final bool isLoading;
  final bool isPosting;
  final String? error;
  final int currentPage;
  final int lastPage;

  const CommentsState({
    this.comments = const [],
    this.isLoading = false,
    this.isPosting = false,
    this.error,
    this.currentPage = 1,
    this.lastPage = 1,
  });

  bool get hasMore => currentPage < lastPage;

  CommentsState copyWith({
    List<CommentModel>? comments,
    bool? isLoading,
    bool? isPosting,
    String? error,
    int? currentPage,
    int? lastPage,
  }) {
    return CommentsState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isPosting: isPosting ?? this.isPosting,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
    );
  }
}

class CommentsNotifier extends StateNotifier<CommentsState> {
  final ApiClient _apiClient;
  final int matchId;

  CommentsNotifier(this._apiClient, this.matchId) : super(const CommentsState());

  Future<void> fetchComments({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isLoading: true, comments: [], currentPage: 1);
    } else {
      state = state.copyWith(isLoading: true);
    }

    try {
      final response = await _apiClient.get('/matches/$matchId/comments');
      final data = response.data;
      final List<dynamic> jsonList = data['comments'] ?? [];
      final comments = jsonList.map((e) => CommentModel.fromJson(e)).toList();
      state = state.copyWith(
        comments: comments,
        isLoading: false,
        currentPage: data['current_page'] ?? 1,
        lastPage: data['last_page'] ?? 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> postComment(String body) async {
    state = state.copyWith(isPosting: true);
    try {
      final response = await _apiClient.post(
        '/matches/$matchId/comments',
        data: {'body': body},
      );
      final newComment = CommentModel.fromJson(response.data['comment']);
      state = state.copyWith(
        isPosting: false,
        comments: [newComment, ...state.comments],
      );
      return true;
    } catch (e) {
      state = state.copyWith(isPosting: false, error: e.toString());
      return false;
    }
  }

  Future<void> likeComment(int commentId) async {
    try {
      await _apiClient.post('/matches/$matchId/comments/$commentId/like', data: {});
      final updated = state.comments.map((c) {
        if (c.id == commentId) return c.copyWith(likesCount: c.likesCount + 1);
        return c;
      }).toList();
      state = state.copyWith(comments: updated);
    } catch (_) {}
  }

  Future<void> deleteComment(int commentId) async {
    try {
      await _apiClient.delete('/matches/$matchId/comments/$commentId');
      final updated = state.comments.where((c) => c.id != commentId).toList();
      state = state.copyWith(comments: updated);
    } catch (_) {}
  }
}

final commentsProvider = StateNotifierProvider.family<CommentsNotifier, CommentsState, int>(
  (ref, matchId) {
    final client = ref.watch(apiClientProvider);
    return CommentsNotifier(client, matchId)..fetchComments();
  },
);
