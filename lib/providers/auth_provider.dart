import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gains/models/user_models.dart';
import 'package:gains/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserProfile?>>((ref) {
      final authService = ref.watch(authServiceProvider);
      return AuthNotifier(authService);
    });

class AuthNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _init();
  }

  // Başlangıç durumunu kontrol etme
  Future<void> _init() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      state = AsyncValue.data(user);
    } else {
      state = const AsyncValue.data(null);
    }
  }

  // Kullanıcı kaydı yapma
  Future<bool> register({
    required String email,
    required String username,
    required String password,
    required String name,
  }) async {
    state = const AsyncValue.loading();
    try {
      final credential = await _authService.register(email, password, username);
      if (credential != null) {
        final userProfile = await _authService.getCurrentUser();
        state = AsyncValue.data(userProfile);
        return true;
      }
      state = const AsyncValue.data(null);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // Kullanıcı girişi yapma
  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final credential = await _authService.login(email, password);
      if (credential != null) {
        final userProfile = await _authService.getCurrentUser();
        state = AsyncValue.data(userProfile);
        return true;
      }
      state = const AsyncValue.data(null);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // Kullanıcı çıkışı yapma
  Future<void> logout() async {
    await _authService.logout();
    state = const AsyncValue.data(null);
  }
}

final currentUserProvider = Provider<UserProfile?>((ref) {
  final state = ref.watch(authStateProvider);
  return state.value;
});
