import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:service_reminder/core/errors/failure_mapper.dart';
import 'package:service_reminder/core/services/supabase/supabase_client_provider.dart';
import 'package:service_reminder/features/auth/data/datasources/auth_remote_datasource_impl.dart';
import 'package:service_reminder/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:service_reminder/features/auth/domain/repositories/auth_repository.dart';
import 'package:service_reminder/features/auth/domain/usecases/send_otp_usecase.dart';
import 'package:service_reminder/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:service_reminder/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:service_reminder/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:service_reminder/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:service_reminder/features/auth/presentation/providers/auth_state.dart';

// ── Dependency providers ──────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepositoryImpl(AuthRemoteDataSourceImpl(client), client);
});

final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  return SignInUseCase(ref.watch(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.watch(authRepositoryProvider));
});

final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  return SignUpUseCase(ref.watch(authRepositoryProvider));
});

final sendOtpUseCaseProvider = Provider<SendOtpUseCase>((ref) {
  return SendOtpUseCase(ref.watch(authRepositoryProvider));
});

final verifyOtpUseCaseProvider = Provider<VerifyOtpUseCase>((ref) {
  return VerifyOtpUseCase(ref.watch(authRepositoryProvider));
});

// ── Auth controller ───────────────────────────────────────────────────────────

final authControllerProvider =
    StateNotifierProvider<AuthController, LoginState>((ref) {
  return AuthController(
    signIn: ref.watch(signInUseCaseProvider),
    signUp: ref.watch(signUpUseCaseProvider),
    signOut: ref.watch(signOutUseCaseProvider),
    sendOtp: ref.watch(sendOtpUseCaseProvider),
    verifyOtp: ref.watch(verifyOtpUseCaseProvider),
  );
});

class AuthController extends StateNotifier<LoginState> {
  final SignInUseCase _signIn;
  final SignUpUseCase _signUp;
  final SignOutUseCase _signOut;
  final SendOtpUseCase _sendOtp;
  final VerifyOtpUseCase _verifyOtp;

  AuthController({
    required SignInUseCase signIn,
    required SignUpUseCase signUp,
    required SignOutUseCase signOut,
    required SendOtpUseCase sendOtp,
    required VerifyOtpUseCase verifyOtp,
  })  : _signIn = signIn,
        _signUp = signUp,
        _signOut = signOut,
        _sendOtp = sendOtp,
        _verifyOtp = verifyOtp,
        super(const LoginInitial());

  Future<void> signIn({required String email, required String password}) async {
    state = const LoginLoading();
    try {
      await _signIn(email: email, password: password);
      state = const LoginAuthenticated();
    } catch (e) {
      final failure = FailureMapper.fromException(e);
      state = LoginError(failure.message);
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    state = const LoginLoading();
    try {
      await _signUp(email: email, password: password);
      state = const LoginAuthenticated();
    } catch (e) {
      final failure = FailureMapper.fromException(e);
      state = LoginError(failure.message);
    }
  }

  Future<void> signOut() async {
    try {
      await _signOut();
    } catch (_) {
      // Sign-out failures are non-critical; GoRouter redirects anyway.
    }
    state = const LoginInitial();
  }

  /// Sends a 6-digit OTP SMS. On success, state becomes [OtpSent].
  Future<void> sendOtp({required String phone}) async {
    state = const LoginLoading();
    try {
      await _sendOtp(phone: phone);
      state = OtpSent(phone);
    } catch (e) {
      final failure = FailureMapper.fromException(e);
      state = LoginError(failure.message);
    }
  }

  /// Verifies the OTP code. On success, state becomes [LoginAuthenticated].
  Future<void> verifyOtp({required String phone, required String token}) async {
    state = const LoginLoading();
    try {
      await _verifyOtp(phone: phone, token: token);
      state = const LoginAuthenticated();
    } catch (e) {
      final failure = FailureMapper.fromException(e);
      state = LoginError(failure.message);
    }
  }

  void clearError() {
    if (state is LoginError) state = const LoginInitial();
  }

  /// Resets back to initial (e.g. user taps "Change number").
  void resetToInitial() => state = const LoginInitial();
}
