import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../auth/auth_provider.dart';

class ProfileState {
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  ProfileState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  ProfileState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ApiClient _apiClient;
  final Ref _ref;

  ProfileNotifier(this._apiClient, this._ref) : super(ProfileState());

  Future<bool> updateProfile({
    required String name,
    required String email,
    String? avatarUrl,
  }) async {
    state = ProfileState(isLoading: true);
    try {
      final response = await _apiClient.put('/profile', data: {
        'name': name,
        'email': email,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      });

      if (response.statusCode == 200) {
        final updatedUser = response.data['user'];
        _ref.read(authProvider.notifier).updateSession(
              name: updatedUser['name'],
              email: updatedUser['email'],
              avatarUrl: updatedUser['avatar_url'],
            );
        state = ProfileState(isSuccess: true);
        return true;
      } else {
        state = ProfileState(errorMessage: 'Failed to update profile');
      }
    } catch (e) {
      state = ProfileState(errorMessage: e.toString());
    }
    return false;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    state = ProfileState(isLoading: true);
    try {
      final response = await _apiClient.put('/profile/password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      });

      if (response.statusCode == 200) {
        state = ProfileState(isSuccess: true);
        return true;
      } else {
        state = ProfileState(errorMessage: 'Failed to change password');
      }
    } catch (e) {
      state = ProfileState(errorMessage: e.toString());
    }
    return false;
  }

  void resetState() {
    state = ProfileState();
  }
}

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final client = ref.watch(apiClientProvider);
  return ProfileNotifier(client, ref);
});
