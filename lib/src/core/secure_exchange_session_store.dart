import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'exchange_api_client.dart';
import 'exchange_session_controller.dart';

class SecureExchangeSessionStore implements ExchangeSessionStore {
  SecureExchangeSessionStore({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _sessionKey = 'hana_local_exchange.auth_session';

  final FlutterSecureStorage _secureStorage;

  @override
  Future<AuthSession?> read() async {
    final encodedSession = await _secureStorage.read(key: _sessionKey);
    if (encodedSession == null || encodedSession.isEmpty) {
      return null;
    }

    try {
      final decodedSession = jsonDecode(encodedSession);
      if (decodedSession is! Map<String, dynamic>) {
        await clear();
        return null;
      }
      return AuthSession.fromJson(decodedSession);
    } on Object {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthSession session) async {
    await _secureStorage.write(
      key: _sessionKey,
      value: jsonEncode(session.toJson()),
    );
  }

  @override
  Future<void> clear() async {
    await _secureStorage.delete(key: _sessionKey);
  }
}
