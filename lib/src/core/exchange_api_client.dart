import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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
  const SignUpResult({required this.username, required this.accountId});

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
    this.errors = const [],
    this.timestamp,
  });

  final bool success;
  final int status;
  final String code;
  final String message;
  final T? data;
  final List<ApiFieldError> errors;
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
      errors: _parseFieldErrors(json['errors']),
      timestamp: AuthSession._parseDateTime(json['timestamp']),
    );
  }

  static List<ApiFieldError> _parseFieldErrors(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Map>()
        .map((item) => ApiFieldError.fromJson(item))
        .toList(growable: false);
  }
}

class ApiFieldError {
  const ApiFieldError({
    required this.field,
    required this.reason,
  });

  final String field;
  final String reason;

  static ApiFieldError fromJson(Map<dynamic, dynamic> json) {
    return ApiFieldError(
      field: '${json['field'] ?? ''}',
      reason: '${json['reason'] ?? ''}',
    );
  }
}

class ExchangeApiException implements Exception {
  const ExchangeApiException({
    required this.status,
    required this.code,
    required this.message,
    this.errors = const [],
  });

  final int status;
  final String code;
  final String message;
  final List<ApiFieldError> errors;

  @override
  String toString() {
    return 'ExchangeApiException(status: $status, code: $code, message: $message)';
  }
}

typedef AuthSessionProvider = AuthSession? Function();
typedef UnauthorizedHandler = void Function();

class ExchangeApiClient {
  ExchangeApiClient({
    required Uri baseUri,
    required http.Client httpClient,
    AuthSessionProvider? sessionProvider,
    UnauthorizedHandler? onUnauthorized,
    Duration requestTimeout = const Duration(seconds: 30),
    Duration uploadTimeout = const Duration(seconds: 60),
  })  : _baseUri = baseUri,
        _httpClient = httpClient,
        _sessionProvider = sessionProvider ?? (() => null),
        _onUnauthorized = onUnauthorized,
        _requestTimeout = requestTimeout,
        _uploadTimeout = uploadTimeout;

  final Uri _baseUri;
  final http.Client _httpClient;
  final AuthSessionProvider _sessionProvider;
  final UnauthorizedHandler? _onUnauthorized;
  final Duration _requestTimeout;
  final Duration _uploadTimeout;

  Future<SignUpResult> signUp({
    required String username,
    required String password,
    required String confirmPassword,
    required String pin,
    required String confirmPin,
  }) async {
    final envelope = await post<SignUpResult>(
      '/api/v1/auth/signup',
      body: {
        'username': username,
        'password': password,
        'confirmPassword': confirmPassword,
        'pin': pin,
        'confirmPin': confirmPin,
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
      body: {'username': username, 'password': password},
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

  Future<ApiEnvelope<Map<String, dynamic>>> verifyToken(String accessToken) {
    return post<Map<String, dynamic>>(
      '/api/v1/auth/token/verify',
      body: {'accessToken': accessToken},
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> logout(String refreshToken) {
    return post<Map<String, dynamic>>(
      '/api/v1/auth/logout',
      body: {'refreshToken': refreshToken},
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getAccount(String accountId) {
    return get<Map<String, dynamic>>('/api/v1/accounts/$accountId');
  }

  Future<ApiEnvelope<Map<String, dynamic>>> depositUsd({
    required String accountId,
    required num amount,
    required String pin,
  }) {
    return post<Map<String, dynamic>>(
      '/api/v1/accounts/$accountId/deposits',
      body: {'amountUsd': amount, 'pin': pin},
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
        if (stockCodes.isNotEmpty) 'stockCodes': stockCodes,
      },
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getMarketQuote({
    required String stockCode,
    String currency = 'USD',
  }) {
    return get<Map<String, dynamic>>(
      '/api/v1/market/quotes/$stockCode',
      query: {'currency': currency},
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getMarketIndices() {
    return get<Map<String, dynamic>>('/api/v1/market/indices');
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getMarketIndexIntraday({
    required String indexCode,
    String? date,
    int limit = 390,
  }) {
    return get<Map<String, dynamic>>(
      '/api/v1/market/indices/$indexCode/intraday',
      query: {
        if (date != null && date.isNotEmpty) 'date': date,
        'limit': '$limit',
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

  Future<ApiEnvelope<Map<String, dynamic>>> searchStocks({
    required String query,
    String? market,
    String currency = 'USD',
    int limit = 20,
  }) {
    return get<Map<String, dynamic>>(
      '/api/v1/stocks/search',
      query: {
        'query': query,
        if (market != null && market.isNotEmpty && market != 'ALL')
          'market': market,
        'currency': currency,
        'limit': '$limit',
      },
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getStockSearchRankings({
    int windowHours = 24,
    int limit = 10,
  }) {
    return get<Map<String, dynamic>>(
      '/api/v1/stocks/search-rankings',
      query: {
        'windowHours': '$windowHours',
        'limit': '$limit',
      },
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> recordStockSearchEvent({
    required String stockCode,
    required String stockName,
    String? market,
    String? sector,
  }) {
    return post<Map<String, dynamic>>(
      '/api/v1/stocks/search-events',
      body: {
        'stockCode': stockCode,
        'stockName': stockName,
        if (market != null && market.isNotEmpty) 'market': market,
        if (sector != null && sector.isNotEmpty) 'sector': sector,
      },
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

  Future<ApiEnvelope<Map<String, dynamic>>> getGlobalPeers({
    required String stockCode,
  }) {
    return get<Map<String, dynamic>>('/api/v1/stocks/$stockCode/global-peers');
  }

  Future<ApiEnvelope<Map<String, dynamic>>> subscribeRealtimeSource({
    required String stockCode,
    String session = 'REGULAR',
  }) {
    return post<Map<String, dynamic>>(
      '/api/v1/market/stocks/$stockCode/realtime-subscription',
      query: {'session': session},
      body: const {},
      decodeData: (value) => _asMap(value),
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> unsubscribeRealtimeSource({
    required String stockCode,
    String session = 'REGULAR',
  }) {
    return delete<Map<String, dynamic>>(
      '/api/v1/market/stocks/$stockCode/realtime-subscription',
      query: {'session': session},
      decodeData: (value) => _asMap(value),
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

  Future<ApiEnvelope<Map<String, dynamic>>> getWatchlist(String accountId) {
    return get<Map<String, dynamic>>('/api/v1/accounts/$accountId/watchlist');
  }

  Future<ApiEnvelope<Map<String, dynamic>>> addWatchlistItem({
    required String accountId,
    required String stockCode,
  }) {
    return post<Map<String, dynamic>>(
      '/api/v1/accounts/$accountId/watchlist',
      body: {'stockCode': stockCode},
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> removeWatchlistItem({
    required String accountId,
    required String stockCode,
  }) {
    return delete<Map<String, dynamic>>(
      '/api/v1/accounts/$accountId/watchlist/$stockCode',
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

  Future<ApiEnvelope<Map<String, dynamic>>> getTradeHistory(
    String accountId, {
    int limit = 50,
  }) {
    return get<Map<String, dynamic>>(
      '/api/v1/accounts/$accountId/trades',
      query: {'limit': '$limit'},
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getOrderHistory(
    String accountId, {
    int limit = 50,
  }) {
    return get<Map<String, dynamic>>(
      '/api/v1/accounts/$accountId/orders',
      query: {'limit': '$limit'},
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> checkOrderability({
    required String accountId,
    required String stockCode,
    required String side,
    required int quantity,
  }) {
    return get<Map<String, dynamic>>(
      '/api/v1/accounts/$accountId/trades/orderability',
      query: {'stockCode': stockCode, 'side': side, 'quantity': '$quantity'},
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> executeTrade({
    required String accountId,
    required String stockCode,
    required String side,
    required int quantity,
    String orderType = 'LIMIT',
    num? limitPriceUsd,
    required String pin,
  }) {
    return post<Map<String, dynamic>>(
      '/api/v1/accounts/$accountId/trades',
      body: <String, dynamic>{
        'stockCode': stockCode,
        'side': side,
        'quantity': quantity,
        'orderType': orderType,
        if (limitPriceUsd != null) 'limitPriceUsd': limitPriceUsd,
        'pin': pin,
      },
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getNotifications(String accountId) {
    return get<Map<String, dynamic>>(
      '/api/v1/accounts/$accountId/notifications',
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getNotificationDevices(
    String accountId,
  ) {
    return get<Map<String, dynamic>>(
      '/api/v1/accounts/$accountId/notifications/devices',
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> registerNotificationDevice({
    required String accountId,
    required String platform,
    required String provider,
    required String deviceToken,
    String? appVersion,
    String? locale,
  }) {
    return post<Map<String, dynamic>>(
      '/api/v1/accounts/$accountId/notifications/devices',
      body: {
        'platform': platform,
        'provider': provider,
        'deviceToken': deviceToken,
        if (appVersion != null && appVersion.isNotEmpty)
          'appVersion': appVersion,
        if (locale != null && locale.isNotEmpty) 'locale': locale,
      },
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> disableNotificationDevice({
    required String accountId,
    required String deviceTokenId,
  }) {
    return delete<Map<String, dynamic>>(
      '/api/v1/accounts/$accountId/notifications/devices/$deviceTokenId',
    );
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
    String stockCode, {
    int limit = 20,
    String? cursor,
  }) {
    return get<Map<String, dynamic>>(
      '/api/v1/stocks/$stockCode/intelligence',
      query: {
        'limit': '$limit',
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getMarketNews({
    int limit = 20,
    String? cursor,
  }) {
    return get<Map<String, dynamic>>(
      '/api/v1/market/news',
      query: {
        'limit': '$limit',
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getTrendingMarketNews({
    int windowHours = 24,
    int limit = 10,
  }) {
    return get<Map<String, dynamic>>(
      '/api/v1/market/news/trending',
      query: {
        'windowHours': '$windowHours',
        'limit': '$limit',
      },
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getMarketCalendar({int limit = 6}) {
    return get<Map<String, dynamic>>(
      '/api/v1/market/calendar',
      query: {'limit': '$limit'},
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getMarketNewsDetail(String newsId) {
    return get<Map<String, dynamic>>('/api/v1/market/news/$newsId');
  }

  Future<ApiEnvelope<Map<String, dynamic>>> explainFinancialTerm({
    required String term,
    required String sourceType,
    String? title,
    String? context,
    String? stockCode,
    String? stockName,
    String? articleId,
    String? articleUrl,
    String? sessionKey,
  }) {
    return post<Map<String, dynamic>>(
      '/api/v1/financial-terms/explain',
      body: {
        'term': term,
        'locale': 'en',
        'sourceType': sourceType,
        if (title != null && title.isNotEmpty) 'title': title,
        if (context != null && context.isNotEmpty) 'context': context,
        if (stockCode != null && stockCode.isNotEmpty) 'stockCode': stockCode,
        if (stockName != null && stockName.isNotEmpty) 'stockName': stockName,
        if (articleId != null && articleId.isNotEmpty) 'articleId': articleId,
        if (articleUrl != null && articleUrl.isNotEmpty)
          'articleUrl': articleUrl,
        if (sessionKey != null && sessionKey.isNotEmpty)
          'sessionKey': sessionKey,
        'allowWebSearch': true,
      },
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getTaxRefundStatus(
    String accountId,
  ) {
    return get<Map<String, dynamic>>(
      '/api/v1/accounts/$accountId/tax/refund-status',
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> uploadTaxDocument({
    required String accountId,
    required String documentType,
    required String fileName,
    required Uint8List bytes,
    String? contentType,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/api/v1/accounts/$accountId/tax/documents', null),
    );
    request.headers.addAll({
      'Accept': 'application/json',
      ...?_sessionProvider()?.authHeaders,
    });
    request.fields['documentType'] = documentType;
    final mediaType = _parseMediaType(contentType);
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: mediaType,
      ),
    );

    final streamedResponse = await _sendWithTimeout(
      request,
      timeout: _uploadTimeout,
    );
    final response = await http.Response.fromStream(streamedResponse);
    return _decodeEnvelope<Map<String, dynamic>>(
      response,
      (value) => _asMap(value),
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> getTaxDocumentVerification({
    required String accountId,
    required String documentId,
  }) {
    return get<Map<String, dynamic>>(
      '/api/v1/accounts/$accountId/tax/documents/$documentId/verification',
    );
  }

  MediaType? _parseMediaType(String? contentType) {
    final normalized = contentType?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    try {
      return MediaType.parse(normalized);
    } on FormatException {
      return null;
    }
  }

  Future<ApiEnvelope<Map<String, dynamic>>> createTaxRefundCase({
    required String accountId,
    required int taxYear,
    required String treatyCountry,
    required String residenceCertificateFileName,
    required String reducedTaxApplicationFileName,
    String? residenceCertificateDocumentId,
    String? apostilleDocumentId,
    String? reducedTaxApplicationDocumentId,
    required bool advancePaymentRequested,
  }) {
    return post<Map<String, dynamic>>(
      '/api/v1/accounts/$accountId/tax/refund-cases',
      body: {
        'taxYear': taxYear,
        'treatyCountry': treatyCountry,
        'residenceCertificateFileName': residenceCertificateFileName,
        'reducedTaxApplicationFileName': reducedTaxApplicationFileName,
        if (residenceCertificateDocumentId != null &&
            residenceCertificateDocumentId.isNotEmpty)
          'residenceCertificateDocumentId': residenceCertificateDocumentId,
        if (apostilleDocumentId != null && apostilleDocumentId.isNotEmpty)
          'apostilleDocumentId': apostilleDocumentId,
        if (reducedTaxApplicationDocumentId != null &&
            reducedTaxApplicationDocumentId.isNotEmpty)
          'reducedTaxApplicationDocumentId': reducedTaxApplicationDocumentId,
        'advancePaymentRequested': advancePaymentRequested,
      },
    );
  }

  Future<ApiEnvelope<Map<String, dynamic>>> syncTaxRefundStatus(
    String accountId,
  ) {
    return post<Map<String, dynamic>>(
      '/api/v1/accounts/$accountId/tax/refund-status/sync',
    );
  }

  Future<ApiEnvelope<T>> get<T>(
    String path, {
    Map<String, Object?>? query,
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
    Map<String, Object?>? query,
    Map<String, Object?>? body,
    T Function(Object? value)? decodeData,
  }) {
    return _send<T>(
      method: 'POST',
      path: path,
      query: query,
      body: body,
      decodeData: decodeData ?? (value) => _asMap(value) as T,
    );
  }

  Future<ApiEnvelope<T>> delete<T>(
    String path, {
    Map<String, Object?>? query,
    T Function(Object? value)? decodeData,
  }) {
    return _send<T>(
      method: 'DELETE',
      path: path,
      query: query,
      decodeData: decodeData ?? (value) => _asMap(value) as T,
    );
  }

  Future<ApiEnvelope<T>> _send<T>({
    required String method,
    required String path,
    required T Function(Object? value) decodeData,
    Map<String, Object?>? query,
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

    final streamedResponse = await _sendWithTimeout(
      request,
      timeout: _requestTimeout,
    );
    final response = await http.Response.fromStream(streamedResponse);
    return _decodeEnvelope<T>(response, decodeData);
  }

  Future<http.StreamedResponse> _sendWithTimeout(
    http.BaseRequest request, {
    required Duration timeout,
  }) async {
    try {
      return await _httpClient.send(request).timeout(timeout);
    } on TimeoutException {
      throw const ExchangeApiException(
        status: 408,
        code: 'EXCHANGE_API_TIMEOUT',
        message: 'The exchange API request timed out.',
      );
    }
  }

  ApiEnvelope<T> _decodeEnvelope<T>(
    http.Response response,
    T Function(Object? value) decodeData,
  ) {
    final decoded = _decodeJsonObject(response.body);
    final envelope = ApiEnvelope.fromJson<T>(decoded, decodeData);

    if (response.statusCode >= 400 || !envelope.success) {
      final status =
          envelope.status == 0 ? response.statusCode : envelope.status;
      if (status == 401) {
        _onUnauthorized?.call();
      }
      throw ExchangeApiException(
        status: status,
        code: envelope.code,
        message: _errorMessage(envelope),
        errors: envelope.errors,
      );
    }

    return envelope;
  }

  Uri _uri(String path, Map<String, Object?>? query) {
    final normalizedBasePath = _baseUri.path.endsWith('/')
        ? _baseUri.path.substring(0, _baseUri.path.length - 1)
        : _baseUri.path;
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    final queryParameters = <String, Object>{};
    query?.forEach((key, value) {
      if (value == null) {
        return;
      }
      if (value is Iterable) {
        final values = value.map((item) => '$item').toList(growable: false);
        if (values.isNotEmpty) {
          queryParameters[key] = values;
        }
        return;
      }
      queryParameters[key] = '$value';
    });

    return _baseUri.replace(
      path: '$normalizedBasePath$normalizedPath',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
  }

  static Map<String, dynamic> _decodeJsonObject(String responseBody) {
    final decoded = jsonDecode(responseBody);
    return _asMap(decoded);
  }

  static String _errorMessage<T>(ApiEnvelope<T> envelope) {
    if (envelope.code == 'COMMON_002' && envelope.errors.isNotEmpty) {
      final messages = envelope.errors
          .map(_validationMessage)
          .where((message) => message.isNotEmpty)
          .toSet()
          .toList(growable: false);
      if (messages.isNotEmpty) {
        return messages.join('\n');
      }
    }
    return envelope.message;
  }

  static String _validationMessage(ApiFieldError error) {
    final field = error.field.toLowerCase();
    final reason = error.reason.toLowerCase();
    final isRequired = reason.contains('blank') ||
        reason.contains('null') ||
        reason.contains('empty') ||
        reason.contains('required');
    if (field.endsWith('username')) {
      return isRequired
          ? 'Username is required.'
          : 'Username must be 4-30 letters, numbers, or underscores.';
    }
    if (field.endsWith('password')) {
      return isRequired
          ? 'Password is required.'
          : 'Password must be 8-72 characters.';
    }
    final label = error.field.isEmpty ? 'Field' : error.field;
    return error.reason.isEmpty
        ? '$label is invalid.'
        : '$label: ${error.reason}';
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
