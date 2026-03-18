import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_tables.dart';
import '../../../core/errors/app_exception.dart' as app_errors;
import '../../../core/errors/failure.dart';
import '../../../shared/models/app_user.dart';
import '../domain/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;

  AuthRepositoryImpl(this._supabase);

  @override
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        return const Failure(app_errors.AuthException('Login failed'));
      }

      final isEmailVerified = response.user!.emailConfirmedAt != null;

      final profile = await _supabase
          .from(SupabaseTables.profiles)
          .select()
          .eq(SupabaseTables.colId, response.user!.id)
          .single();

      return Success(AppUser.fromMap({
        ...profile,
        'email': response.user!.email ?? '',
        'is_email_verified': isEmailVerified,
      }));
    } on AuthApiException catch (e) {
      return Failure(app_errors.AuthException(e.message));
    } catch (e) {
      return Failure(app_errors.NetworkException(e.toString()));
    }
  }

  @override
  Future<Result<AppUser>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String employeeId,
    required String department,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: dotenv.env['SUPABASE_REDIRECT_URL'],
      );
      if (response.user == null) {
        return const Failure(app_errors.AuthException('Sign up failed'));
      }

      // Insert profile
      await _supabase.from(SupabaseTables.profiles).insert({
        SupabaseTables.colId: response.user!.id,
        SupabaseTables.colFullName: fullName,
        SupabaseTables.colEmployeeId: employeeId,
        SupabaseTables.colDepartment: department,
        SupabaseTables.colRole: 'teacher',
      });

      return Success(AppUser(
        id: response.user!.id,
        email: email,
        fullName: fullName,
        employeeId: employeeId,
        department: department,
        isEmailVerified: response.user!.emailConfirmedAt != null,
      ));
    } on AuthApiException catch (e) {
      return Failure(app_errors.AuthException(e.message));
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return const Failure(
            app_errors.AuthException('Employee ID already registered'));
      }
      return Failure(app_errors.AuthException(e.message));
    } catch (e) {
      return Failure(app_errors.NetworkException(e.toString()));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _supabase.auth.signOut();
      return const Success(null);
    } catch (e) {
      return Failure(app_errors.AuthException(e.toString()));
    }
  }

  @override
  Future<Result<AppUser>> getCurrentUser() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        return const Failure(app_errors.AuthException('Not authenticated'));
      }

      final user = _supabase.auth.currentUser;
      if (user == null) {
        return const Failure(app_errors.AuthException('Not authenticated'));
      }

      Map<String, dynamic>? profile;
      try {
        profile = await _supabase
            .from(SupabaseTables.profiles)
            .select()
            .eq(SupabaseTables.colId, user.id)
            .single();
      } catch (_) {
        // Offline or backend error, proceed with default profile data
      }

      return Success(AppUser.fromMap({
        ...(profile ?? {
          SupabaseTables.colFullName: 'Teacher (Offline)',
          SupabaseTables.colEmployeeId: '',
          SupabaseTables.colDepartment: '',
          SupabaseTables.colRole: 'teacher',
        }),
        'email': user.email ?? '',
        'is_email_verified': user.emailConfirmedAt != null,
      }));
    } catch (e) {
      return const Failure(app_errors.AuthException('Not authenticated'));
    }
  }

  @override
  Future<Result<void>> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return const Success(null);
    } catch (e) {
      return Failure(app_errors.AuthException(e.toString()));
    }
  }

  @override
  Future<Result<void>> resendVerification(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: dotenv.env['SUPABASE_REDIRECT_URL'],
      );
      return const Success(null);
    } catch (e) {
      return Failure(app_errors.AuthException(e.toString()));
    }
  }

  @override
  Stream<AppUser?> watchAuthState() {
    return _supabase.auth.onAuthStateChange.asyncMap((data) async {
      if (data.session == null) return null;

      Map<String, dynamic>? profile;
      try {
        profile = await _supabase
            .from(SupabaseTables.profiles)
            .select()
            .eq(SupabaseTables.colId, data.session!.user.id)
            .single();
      } catch (_) {
        // Ignore offline errors
      }

      return AppUser.fromMap({
        ...(profile ?? {
          SupabaseTables.colFullName: 'Teacher (Offline)',
          SupabaseTables.colEmployeeId: '',
          SupabaseTables.colDepartment: '',
          SupabaseTables.colRole: 'teacher',
        }),
        'email': data.session!.user.email ?? '',
        'is_email_verified': data.session!.user.emailConfirmedAt != null,
      });
    });
  }
}
