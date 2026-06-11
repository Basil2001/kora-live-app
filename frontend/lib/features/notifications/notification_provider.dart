import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../auth/auth_provider.dart';
import 'notification_service.dart';

class AppNotificationModel {
  final int id;
  final int? userId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? sentAt;
  final DateTime createdAt;

  AppNotificationModel({
    required this.id,
    this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.isRead,
    this.sentAt,
    required this.createdAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'system',
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : null,
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class NotificationPreferencesModel {
  final bool goals;
  final bool matchStart;
  final bool matchEnd;
  final bool news;
  final bool promotions;

  NotificationPreferencesModel({
    required this.goals,
    required this.matchStart,
    required this.matchEnd,
    required this.news,
    required this.promotions,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      goals: json['goals'] == 1 || json['goals'] == true,
      matchStart: json['match_start'] == 1 || json['match_start'] == true,
      matchEnd: json['match_end'] == 1 || json['match_end'] == true,
      news: json['news'] == 1 || json['news'] == true,
      promotions: json['promotions'] == 1 || json['promotions'] == true,
    );
  }

  NotificationPreferencesModel copyWith({
    bool? goals,
    bool? matchStart,
    bool? matchEnd,
    bool? news,
    bool? promotions,
  }) {
    return NotificationPreferencesModel(
      goals: goals ?? this.goals,
      matchStart: matchStart ?? this.matchStart,
      matchEnd: matchEnd ?? this.matchEnd,
      news: news ?? this.news,
      promotions: promotions ?? this.promotions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goals': goals,
      'match_start': matchStart,
      'match_end': matchEnd,
      'news': news,
      'promotions': promotions,
    };
  }
}

// Service Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final client = ref.watch(apiClientProvider);
  return NotificationService(client);
});

// Notifications List State
class NotificationsState {
  final List<AppNotificationModel> items;
  final bool isLoading;
  final String? errorMessage;

  NotificationsState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  NotificationsState copyWith({
    List<AppNotificationModel>? items,
    bool? isLoading,
    String? errorMessage,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final ApiClient _apiClient;

  NotificationsNotifier(this._apiClient) : super(NotificationsState());

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.get('/notifications');
      if (response.statusCode == 200) {
        final List<dynamic> dataList = response.data['data'] ?? [];
        final items = dataList.map((e) => AppNotificationModel.fromJson(e)).toList();
        state = NotificationsState(items: items);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to load notifications');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      final response = await _apiClient.post('/notifications/read/$id');
      if (response.statusCode == 200) {
        state = state.copyWith(
          items: state.items.map((e) {
            if (e.id == id) {
              return AppNotificationModel(
                id: e.id,
                userId: e.userId,
                title: e.title,
                body: e.body,
                type: e.type,
                data: e.data,
                isRead: true,
                sentAt: e.sentAt,
                createdAt: e.createdAt,
              );
            }
            return e;
          }).toList(),
        );
      }
    } catch (e) {
      // Log or handle error
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await _apiClient.post('/notifications/read-all');
      if (response.statusCode == 200) {
        state = state.copyWith(
          items: state.items.map((e) {
            return AppNotificationModel(
              id: e.id,
              userId: e.userId,
              title: e.title,
              body: e.body,
              type: e.type,
              data: e.data,
              isRead: true,
              sentAt: e.sentAt,
              createdAt: e.createdAt,
            );
          }).toList(),
        );
      }
    } catch (e) {
      // Log or handle error
    }
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final client = ref.watch(apiClientProvider);
  return NotificationsNotifier(client);
});

// Notifications Unread Count Provider
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationsProvider);
  return state.items.where((element) => !element.isRead).length;
});

// Notification Preferences Provider
class NotificationPreferencesNotifier
    extends StateNotifier<AsyncValue<NotificationPreferencesModel>> {
  final ApiClient _apiClient;

  NotificationPreferencesNotifier(this._apiClient)
      : super(const AsyncValue.loading()) {
    fetchPreferences();
  }

  Future<void> fetchPreferences() async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.get('/notifications/preferences');
      if (response.statusCode == 200) {
        final model = NotificationPreferencesModel.fromJson(response.data);
        state = AsyncValue.data(model);
      } else {
        state = AsyncValue.error('Failed to fetch preferences', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updatePreferences(NotificationPreferencesModel updated) async {
    try {
      final response = await _apiClient.put(
        '/notifications/preferences',
        data: updated.toJson(),
      );
      if (response.statusCode == 200) {
        final model = NotificationPreferencesModel.fromJson(response.data['preferences']);
        state = AsyncValue.data(model);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final notificationPreferencesProvider = StateNotifierProvider<
    NotificationPreferencesNotifier,
    AsyncValue<NotificationPreferencesModel>>((ref) {
  final client = ref.watch(apiClientProvider);
  return NotificationPreferencesNotifier(client);
});
