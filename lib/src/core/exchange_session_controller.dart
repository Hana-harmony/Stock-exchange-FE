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

  AuthSession? get session => value.session;

  Future<void> restore() async {
    value = const ExchangeSessionState.loading();
    final restoredSession = await _sessionStore.read();
    if (restoredSession == null) {
      value = const ExchangeSessionState.signedOut();
      return;
    }

    value = ExchangeSessionState.signedIn(restoredSession);
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    if (_hasInvalidCredentials(username: username, password: password)) {
      value = ExchangeSessionState.failure('Username and password are required.');
      return;
    }

    value = ExchangeSessionState.loading(session: value.session);
    try {
      final nextSession = await _apiClient.login(
        username: username.trim(),
        password: password,
      );
      await _sessionStore.write(nextSession);
      value = ExchangeSessionState.signedIn(nextSession);
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
  }) async {
    if (_hasInvalidCredentials(username: username, password: password)) {
      value = ExchangeSessionState.failure('Username and password are required.');
      return;
    }

    value = ExchangeSessionState.loading(session: value.session);
    try {
      await _apiClient.signUp(
        username: username.trim(),
        password: password,
      );
      final nextSession = await _apiClient.login(
        username: username.trim(),
        password: password,
      );
      await _sessionStore.write(nextSession);
      value = ExchangeSessionState.signedIn(nextSession);
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
      value = ExchangeSessionState.signedIn(nextSession);
    } on Object {
      await signOut();
    }
  }

  Future<void> signOut() async {
    await _sessionStore.clear();
    value = const ExchangeSessionState.signedOut();
  }

  bool _hasInvalidCredentials({
    required String username,
    required String password,
  }) {
    return username.trim().isEmpty || password.isEmpty;
  }
}
