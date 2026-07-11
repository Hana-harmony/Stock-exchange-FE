import 'dart:async';

import 'package:flutter/foundation.dart';

import 'exchange_api_client.dart';

enum ExchangeSessionStatus {
  signedOut,
  loading,
  signedIn,
  failure,
}

class ExchangeSessionState {
  const ExchangeSessionState({
    required this.status,
    this.session,
    this.errorMessage,
  });

  const ExchangeSessionState.signedOut()
      : status = ExchangeSessionStatus.signedOut,
        session = null,
        errorMessage = null;

  const ExchangeSessionState.loading({this.session})
      : status = ExchangeSessionStatus.loading,
        errorMessage = null;

  const ExchangeSessionState.signedIn(this.session)
      : status = ExchangeSessionStatus.signedIn,
        errorMessage = null;

  const ExchangeSessionState.failure(this.errorMessage, {this.session})
      : status = ExchangeSessionStatus.failure;

  final ExchangeSessionStatus status;
  final AuthSession? session;
  final String? errorMessage;

  bool get isSignedIn => status == ExchangeSessionStatus.signedIn;
}

abstract interface class ExchangeSessionStore {
  Future<AuthSession?> read();

  Future<void> write(AuthSession session);

  Future<void> clear();
}

class MemoryExchangeSessionStore implements ExchangeSessionStore {
  AuthSession? _session;

  @override
  Future<AuthSession?> read() async {
    return _session;
  }

  @override
  Future<void> write(AuthSession session) async {
    _session = session;
  }

  @override
  Future<void> clear() async {
    _session = null;
  }
}

class ExchangeSessionController extends ValueNotifier<ExchangeSessionState> {
  ExchangeSessionController({
    required ExchangeApiClient apiClient,
    required ExchangeSessionStore sessionStore,
  })  : _apiClient = apiClient,
        _sessionStore = sessionStore,
        super(const ExchangeSessionState.signedOut());

  final ExchangeApiClient _apiClient;
  final ExchangeSessionStore _sessionStore;
  Timer? _refreshTimer;

  AuthSession? get session => value.session;

  Future<void> restore() async {
    value = const ExchangeSessionState.loading();
    final restoredSession = await _sessionStore.read();
    if (restoredSession == null) {
      value = const ExchangeSessionState.signedOut();
      return;
    }

    final now = DateTime.now().toUtc();
    final refreshExpiresAt = restoredSession.refreshTokenExpiresAt?.toUtc();
    if (refreshExpiresAt != null && !refreshExpiresAt.isAfter(now)) {
      await _sessionStore.clear();
      value = const ExchangeSessionState.signedOut();
      return;
    }

    final accessExpiresAt = restoredSession.accessTokenExpiresAt?.toUtc();
    if (accessExpiresAt != null &&
        !accessExpiresAt.isAfter(now.add(const Duration(minutes: 1)))) {
      value = ExchangeSessionState.signedIn(restoredSession);
      await refresh();
      return;
    }

    try {
      await _apiClient.verifyToken(restoredSession.accessToken);
      _setSignedIn(restoredSession);
    } on ExchangeApiException catch (error) {
      if (error.status == 401) {
        value = ExchangeSessionState.signedIn(restoredSession);
        await refresh();
        return;
      }
      _setSignedIn(restoredSession);
    } on Object {
      _setSignedIn(restoredSession);
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final validationError = _credentialValidationError(
      username: username,
      password: password,
    );
    if (validationError != null) {
      value = ExchangeSessionState.failure(validationError);
      return;
    }

    value = ExchangeSessionState.loading(session: value.session);
    try {
      final nextSession = await _apiClient.login(
        username: username.trim(),
        password: password,
      );
      await _sessionStore.write(nextSession);
      _setSignedIn(nextSession);
    } on ExchangeApiException catch (error) {
      value = ExchangeSessionState.failure(error.message, session: session);
    } on Object {
      value = ExchangeSessionState.failure(
        'Unable to sign in. Please try again.',
        session: session,
      );
    }
  }

  Future<void> signUpAndLogin({
    required String username,
    required String password,
    required String confirmPassword,
    required String pin,
    required String confirmPin,
  }) async {
    final validationError = _credentialValidationError(
      username: username,
      password: password,
    );
    if (validationError != null) {
      value = ExchangeSessionState.failure(validationError);
      return;
    }
    if (password != confirmPassword) {
      value = const ExchangeSessionState.failure('Passwords do not match.');
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(pin) || pin != confirmPin) {
      value = const ExchangeSessionState.failure(
          'Enter the same 6-digit PIN twice.');
      return;
    }

    value = ExchangeSessionState.loading(session: value.session);
    try {
      await _apiClient.signUp(
        username: username.trim(),
        password: password,
        confirmPassword: confirmPassword,
        pin: pin,
        confirmPin: confirmPin,
      );
      final nextSession = await _apiClient.login(
        username: username.trim(),
        password: password,
      );
      await _sessionStore.write(nextSession);
      _setSignedIn(nextSession);
    } on ExchangeApiException catch (error) {
      value = ExchangeSessionState.failure(error.message, session: session);
    } on Object {
      value = ExchangeSessionState.failure(
        'Unable to create the account. Please try again.',
        session: session,
      );
    }
  }

  Future<void> refresh() async {
    final currentSession = session;
    if (currentSession == null) {
      value = const ExchangeSessionState.signedOut();
      return;
    }

    value = ExchangeSessionState.loading(session: currentSession);
    try {
      final nextSession = await _apiClient.refreshToken(
        currentSession.refreshToken,
      );
      await _sessionStore.write(nextSession);
      _setSignedIn(nextSession);
    } on ExchangeApiException catch (error) {
      if (error.status == 401) {
        await _clearSession();
        return;
      }
      value = ExchangeSessionState.failure(
        'Unable to renew the session. Check your connection.',
        session: currentSession,
      );
      _scheduleRefresh(currentSession, retryDelay: const Duration(seconds: 30));
    } on Object {
      value = ExchangeSessionState.failure(
        'Unable to renew the session. Check your connection.',
        session: currentSession,
      );
      _scheduleRefresh(currentSession, retryDelay: const Duration(seconds: 30));
    }
  }

  Future<void> signOut() async {
    final refreshToken = session?.refreshToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _apiClient.logout(refreshToken);
      } on Object {
        // 로그아웃은 로컬 세션 제거가 우선이다.
      }
    }
    await _clearSession();
  }

  void _setSignedIn(AuthSession session) {
    value = ExchangeSessionState.signedIn(session);
    _scheduleRefresh(session);
  }

  void _scheduleRefresh(
    AuthSession session, {
    Duration? retryDelay,
  }) {
    _refreshTimer?.cancel();
    final expiresAt = session.accessTokenExpiresAt?.toUtc();
    if (expiresAt == null && retryDelay == null) {
      return;
    }
    final delay = retryDelay ??
        (expiresAt!.difference(DateTime.now().toUtc()) -
            const Duration(minutes: 1));
    _refreshTimer = Timer(
      delay.isNegative ? Duration.zero : delay,
      () => unawaited(refresh()),
    );
  }

  Future<void> _clearSession() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    await _sessionStore.clear();
    value = const ExchangeSessionState.signedOut();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String? _credentialValidationError({
    required String username,
    required String password,
  }) {
    final trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty || password.isEmpty) {
      return 'Username and password are required.';
    }
    if (!RegExp(r'^[A-Za-z0-9_]{4,30}$').hasMatch(trimmedUsername)) {
      return 'Username must be 4-30 letters, numbers, or underscores.';
    }
    if (password.length < 8 || password.length > 72) {
      return 'Password must be 8-72 characters.';
    }
    return null;
  }
}
