import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/auth_notifier.dart';
import '../../shared/models/app_user.dart';

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AppUser?>(AuthNotifier.new);

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authNotifierProvider).valueOrNull;
});
