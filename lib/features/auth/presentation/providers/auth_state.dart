/// Login screen state — renamed LoginState to avoid conflict with
/// Supabase's own AuthState type.
sealed class LoginState {
  const LoginState();
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginAuthenticated extends LoginState {
  const LoginAuthenticated();
}

class LoginError extends LoginState {
  final String message;
  const LoginError(this.message);
}

/// OTP was sent to [phone]; UI should now show the code-entry step.
class OtpSent extends LoginState {
  final String phone;
  const OtpSent(this.phone);
}
