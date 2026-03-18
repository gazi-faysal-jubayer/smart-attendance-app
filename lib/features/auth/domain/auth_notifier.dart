import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/failure.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../data/auth_repository_impl.dart';
import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(supabaseProvider));
});

class AuthNotifier extends AsyncNotifier<AppUser?> {
  StreamSubscription<AppUser?>? _authSub;

  @override
  Future<AppUser?> build() async {
    final repo = ref.watch(authRepositoryProvider);

    // Cancel previous subscription if any
    _authSub?.cancel();

    // Listen to auth state changes
    _authSub = repo.watchAuthState().listen((user) {
      state = AsyncData(user);
    });

    // Clean up on dispose
    ref.onDispose(() {
      _authSub?.cancel();
    });

    final result = await repo.getCurrentUser();
    return result.dataOrNull;
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.signIn(email: email, password: password);
    result.when(
      success: (user) => state = AsyncData(user),
      failure: (e) => state = AsyncError(e, StackTrace.current),
    );
    if (result.isFailure) {
      throw result.exceptionOrNull!;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String employeeId,
    required String department,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.signUp(
      email: email,
      password: password,
      fullName: fullName,
      employeeId: employeeId,
      department: department,
    );
    result.when(
      success: (user) => state = AsyncData(user),
      failure: (e) => state = AsyncError(e, StackTrace.current),
    );
    if (result.isFailure) {
      throw result.exceptionOrNull!;
    }
  }

  Future<void> signOut() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.signOut();
    state = const AsyncData(null);
  }

  Future<void> resetPassword(String email) async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.resetPassword(email);
    if (result.isFailure) {
      throw result.exceptionOrNull!;
    }
  }

  Future<void> resendVerification(String email) async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.resendVerification(email);
    if (result.isFailure) {
      throw result.exceptionOrNull!;
    }
  }
}
