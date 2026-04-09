import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/utils/mock_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthState
// Immutable state for the auth notifier — frontend-only, no real backend.
// ─────────────────────────────────────────────────────────────────────────────

class AuthState {
  const AuthState({
    this.isLoggedIn = false,
    this.userEmail,
    this.userName,
    this.isLoading = false,
    this.errorMessage,
  });

  final bool isLoggedIn;
  final String? userEmail;
  final String? userName;
  final bool isLoading;
  final String? errorMessage;

  AuthState copyWith({
    bool? isLoggedIn,
    String? userEmail,
    String? userName,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AuthNotifier
// Mock auth — saves login state to Hive, simulates a 1-second network delay.
// ─────────────────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  /// Mock login — validates inputs, simulates delay, saves to Hive.
  Future<void> mockLogin({
    required String email,
    required String password,
  }) async {
    // Basic validation
    if (email.isEmpty || !email.contains('@')) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid email address',
        clearError: false,
      );
      return;
    }
    if (password.isEmpty || password.length < 6) {
      state = state.copyWith(
        errorMessage: 'Password must be at least 6 characters',
        clearError: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    await Future<void>.delayed(const Duration(milliseconds: 1000));

    // Save logged-in state to Hive
    final box = Hive.box(MockData.boxUserProfile);
    await box.put('logged_in_email', email);
    await box.put('is_logged_in', true);

    state = state.copyWith(
      isLoading: false,
      isLoggedIn: true,
      userEmail: email,
      userName: email.split('@').first,
    );
  }

  /// Mock register — validates inputs, simulates delay, saves to Hive.
  Future<void> mockRegister({
    required String name,
    required String email,
    required String password,
  }) async {
    if (name.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter your name');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid email address',
      );
      return;
    }
    if (password.length < 8) {
      state = state.copyWith(
        errorMessage: 'Password must be at least 8 characters',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    // Save registered user to Hive
    final box = Hive.box(MockData.boxUserProfile);
    await box.put('name', name.trim());
    await box.put('logged_in_email', email.trim());
    await box.put('is_logged_in', true);

    state = state.copyWith(
      isLoading: false,
      isLoggedIn: true,
      userEmail: email.trim(),
      userName: name.trim(),
    );
  }

  /// Check if already logged in (called on app start).
  void checkLoginStatus() {
    final box = Hive.box(MockData.boxUserProfile);
    final email = box.get('logged_in_email') as String?;
    final isLoggedIn = box.get('is_logged_in', defaultValue: false) as bool;

    if (isLoggedIn && email != null) {
      state = state.copyWith(
        isLoggedIn: true,
        userEmail: email,
        userName: email.split('@').first,
      );
    }
  }

  /// Clear the error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Log out — clear Hive auth keys and reset state.
  Future<void> logout() async {
    final box = Hive.box(MockData.boxUserProfile);
    await box.delete('logged_in_email');
    await box.put('is_logged_in', false);
    state = const AuthState();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
