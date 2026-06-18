import 'dart:convert';

import 'package:http/http.dart' as http;

class ExchangeEnvironment {
  const ExchangeEnvironment({
    this.apiBaseUrl = const String.fromEnvironment(
      'EXCHANGE_API_BASE_URL',
      defaultValue: 'http://localhost:3000',
    ),
  });

  final String apiBaseUrl;

  Uri get apiBaseUri => Uri.parse(apiBaseUrl);
}

class AuthSession {
  const AuthSession({
    required this.username,
    required this.accountId,
    required this.tokenType,
    required this.accessToken,
    required this.refreshToken,
    this.accessTokenExpiresAt,
    this.refreshTokenExpiresAt,
  });

  final String username;
  final String accountId;
  final String tokenType;
  final String accessToken;
  final String refreshToken;
  final DateTime? accessTokenExpiresAt;
  final DateTime? refreshTokenExpiresAt;

  Map<String, String> get authHeaders => {
        'Authorization': '$tokenType $accessToken',
      };

  Map<String, Object?> toJson() {
    return {
      'username': username,
      'accountId': accountId,
      'tokenType': tokenType,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'accessTokenExpiresAt': accessTokenExpiresAt?.toUtc().toIso8601String(),
      'refreshTokenExpiresAt': refreshTokenExpiresAt?.toUtc().toIso8601String(),
    };
  }

  static AuthSession fromJson(Map<String, dynamic> json) {
    return AuthSession(
      username: json['username'] as String,
      accountId: json['accountId'] as String,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      accessTokenExpiresAt: _parseDateTime(json['accessTokenExpiresAt']),
      refreshTokenExpiresAt: _parseDateTime(json['refreshTokenExpiresAt']),
    );
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}

class SignUpResult {
  const SignUpResult({
    required this.username,
    required this.accountId,
  });

  final String username;
  final String accountId;

  static SignUpResult fromJson(Map<String, dynamic> json) {
    return SignUpResult(
      username: json['username'] as String,
      accountId: json['accountId'] as String,
    );
  }
}

class ApiEnvelope<T> {
  const ApiEnvelope({
    required this.success,
    required this.status,
    required this.code,
    required this.message,
    required this.data,
    this.timestamp,
  });

  final bool success;
  final int status;
  final String code;
  final String message;
  final T? data;
  final DateTime? timestamp;

  static ApiEnvelope<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Object? value) decodeData,
  ) {
    return ApiEnvelope<T>(
      success: json['success'] as bool? ?? false,
      status: json['status'] as int? ?? 0,
      code: json['code'] as String? ?? 'COMMON_UNKNOWN',
      message: json['message'] as String? ?? 'Unexpected response',
      data: json.containsKey('data') && json['data'] != null
          ? decodeData(json['data'])
          : null,
      timestamp: AuthSession._parseDateTime(json['timestamp']),
    );
  }
}

class ExchangeApiException implements Exception {
  const ExchangeApiException({
    required this.status,
    required this.code,
    required this.message,
  });

  final int status;
  final String code;
  final String message;

  @override
  String toString() {
    return 'ExchangeApiException(status: $status, code: $code, message: $message)';
  }
}

typedef AuthSessionProvider = AuthSession? Function();

class ExchangeApiClient {
  ExchangeApiClient({
    required Uri baseUri,
    required http.Client httpClient,
    AuthSessionProvider? sessionProvider,
  })  : _baseUri = baseUri,
        _httpClient = httpClient,
        _sessionProvider = sessionProvider ?? (() => null);

  final Uri _baseUri;
  final http.Client _httpClient;
  final AuthSessionProvider _sessionProvider;

  Future<SignUpResult> signUp({
    required String username,
    required String password,
  }) async {
    final envelope = await post<SignUpResult>(
      '/api/v1/auth/signup',
      body: {
        'username': username,
        'password': password,
      },
      decodeData: (value) => SignUpResult.fromJson(_asMap(value)),
    );

    return envelope.data!;
  }

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final envelope = await post<AuthSession>(
      '/api/v1/auth/login',
      body: {
        'username': username,
        'password': password,
      },
      decodeData: (value) => AuthSession.fromJson(_asMap(value)),
    );

    return envelope.data!;
  }

  Future<AuthSession> refreshToken(String refreshToken) async {
    final envelope = await post<AuthSession>(
      '/api/v1/auth/token/refresh',
      body: {'refreshToken': refreshToken},
      decodeData: (value) => AuthSession.fromJson(_asMap(value)),
    );

    return envelope.data!;
  }

  Future<ApiEnvelope<Map<String, dynamic>>> verifyToken(
    String accessToken,
  ) {
    return post<Map<String, dynamic>>(
      '/api/v1/auth/token/verify',
      body: {'accessToken': accessToken},
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getAccount(String accountId) {
    return get<Map<String, dynamic>>('/api/v1/accounts/$accountId');
  }

  Future<ApiEnvelope<Map<String, dynamic>>> depositUsd({
    required String accountId,
    required num amount,
  }) {
    return post<Map<String, dynamic>>(
      '/api/v1/accounts/$accountId/deposits',
      body: {'amountUsd': amount},
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getMarketQuotes({
    String? market,
    String currency = 'USD',
    List<String> stockCodes = const [],
  }) {
    return get<Map<String, dynamic>>(
      '/api/v1/market/quotes',
      query: {
        if (market != null && market.isNotEmpty && market != 'ALL')
          'market': market,
        'currency': currency,
        if (stockCodes.isNotEmpty) 'stockCodes': stockCodes.join(','),
      },
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getStockDetail({
    required String stockCode,
    String currency = 'USD',
  }) {
    return get<Map<String, dynamic>>(
      '/api/v1/stocks/$stockCode',
      query: {'currency': currency},
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getMarketChart({
    required String stockCode,
    required String from,
    required String to,
    String interval = '1d',
    String currency = 'USD',
  }) {
    return get<Map<String, dynamic>>(
      '/api/v1/market/stocks/$stockCode/chart',
      query: {
        'from': from,
        'to': to,
        'interval': interval,
        'currency': currency,
      },
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getOrderBook({
    required String stockCode,
    String currency = 'USD',
  }) {
    return get<Map<String, dynamic>>(
      '/api/v1/market/stocks/$stockCode/orderbook',
      query: {'currency': currency},
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getWatchlistQuotes(
    String accountId, {
    String? market,
    String currency = 'USD',
  }) {
    return get<Map<String, dynamic>>(
      '/api/v1/accounts/$accountId/market/quotes/watchlist',
      query: {
        if (market != null && market.isNotEmpty && market != 'ALL')
          'market': market,
        'currency': currency,
      },
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getPortfolioQuotes(
    String accountId, {
    String? market,
    String currency = 'USD',
  }) {
    return get<Map<String, dynamic>>(
      '/api/v1/accounts/$accountId/market/quotes/portfolio',
      query: {
        if (market != null && market.isNotEmpty && market != 'ALL')
          'market': market,
        'currency': currency,
      },
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getPortfolio(String accountId) {
    return get<Map<String, dynamic>>('/api/v1/accounts/$accountId/portfolio');
  }

  Future<ApiEnvelope<Map<String, dynamic>>> checkOrderability({
    required String accountId,
    required String stockCode,
    required String side,
    required int quantity,
  }) {
    return get<Map<String, dynamic>>(
      '/api/v1/accounts/$accountId/trades/orderability',
      query: {
        'stockCode': stockCode,
        'side': side,
        'quantity': '$quantity',
      },
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> executeTrade({
    required String accountId,
    required String stockCode,
    required String side,
    required int quantity,
  }) {
    return post<Map<String, dynamic>>(
      '/api/v1/accounts/$accountId/trades',
      body: {
        'stockCode': stockCode,
        'side': side,
        'quantity': quantity,
      },
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getNotifications(
    String accountId,
  ) {
    return get<Map<String, dynamic>>('/api/v1/accounts/$accountId/notifications');
  }

  Future<ApiEnvelope<Map<String, dynamic>>> markNotificationRead({
    required String accountId,
    required String notificationId,
  }) {
    return post<Map<String, dynamic>>(
      '/api/v1/accounts/$accountId/notifications/$notificationId/read',
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getStockIntelligenceFeed(
    String stockCode,
  ) {
    return get<Map<String, dynamic>>('/api/v1/stocks/$stockCode/intelligence');
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getTaxRefundStatus(
    String accountId,
  ) {
    return get<Map<String, dynamic>>(
      '/api/v1/accounts/$accountId/tax/refund-status',
    );
  }

  Future<ApiEnvelope<T>> get<T>(
    String path, {
    Map<String, String>? query,
    T Function(Object? value)? decodeData,
  }) {
    return _send<T>(
      method: 'GET',
      path: path,
      query: query,
      decodeData: decodeData ?? (value) => _asMap(value) as T,
    );
  }

  Future<ApiEnvelope<T>> post<T>(
    String path, {
    Map<String, Object?>? body,
    T Function(Object? value)? decodeData,
  }) {
    return _send<T>(
      method: 'POST',
      path: path,
      body: body,
      decodeData: decodeData ?? (value) => _asMap(value) as T,
    );
  }

  Future<ApiEnvelope<T>> _send<T>({
    required String method,
    required String path,
    required T Function(Object? value) decodeData,
    Map<String, String>? query,
    Map<String, Object?>? body,
  }) async {
    final request = http.Request(method, _uri(path, query));
    request.headers.addAll({
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...?_sessionProvider()?.authHeaders,
    });
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    final decoded = _decodeJsonObject(response.body);
    final envelope = ApiEnvelope.fromJson<T>(decoded, decodeData);

    if (response.statusCode >= 400 || !envelope.success) {
      throw ExchangeApiException(
        status: envelope.status == 0 ? response.statusCode : envelope.status,
        code: envelope.code,
        message: envelope.message,
      );
    }

    return envelope;
  }

  Uri _uri(String path, Map<String, String>? query) {
    final normalizedBasePath = _baseUri.path.endsWith('/')
        ? _baseUri.path.substring(0, _baseUri.path.length - 1)
        : _baseUri.path;
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    return _baseUri.replace(
      path: '$normalizedBasePath$normalizedPath',
      queryParameters: query == null || query.isEmpty ? null : query,
    );
  }

  static Map<String, dynamic> _decodeJsonObject(String responseBody) {
    final decoded = jsonDecode(responseBody);
    return _asMap(decoded);
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry('$key', value));
    }
    throw const FormatException('Expected JSON object');
  }
}
