import '../../../shared/models/app_user.dart';
import '../../../core/errors/failure.dart';

abstract class AuthRepository {
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  });

  Future<Result<AppUser>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String employeeId,
    required String department,
  });

  Future<Result<void>> signOut();

  Future<Result<AppUser>> getCurrentUser();

  Future<Result<void>> resetPassword(String email);

  Future<Result<void>> resendVerification(String email);

  Stream<AppUser?> watchAuthState();
}
