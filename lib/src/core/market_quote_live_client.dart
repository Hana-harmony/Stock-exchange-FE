import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

typedef QuoteSocketConnector = QuoteSocketConnection Function(Uri uri);

abstract class QuoteSocketConnection {
  Stream<dynamic> get stream;

  void add(String message);

  Future<void> close();
}

class WebSocketQuoteSocketConnection implements QuoteSocketConnection {
  WebSocketQuoteSocketConnection(Uri uri)
      : _channel = WebSocketChannel.connect(uri);

  final WebSocketChannel _channel;

  @override
  Stream<dynamic> get stream => _channel.stream;

  @override
  void add(String message) {
    _channel.sink.add(message);
  }

  @override
  Future<void> close() async {
    await _channel.sink.close();
  }
}

class MarketQuoteLiveSubscription {
  const MarketQuoteLiveSubscription({
    this.market,
    this.stockCodes = const [],
    this.accountId,
    this.accountScope,
  });

  final String? market;
  final List<String> stockCodes;
  final String? accountId;
  final MarketQuoteAccountScope? accountScope;

  List<String> get topics {
    if (accountId != null && accountId!.isNotEmpty && accountScope != null) {
      final scope = accountScope == MarketQuoteAccountScope.watchlist
          ? 'watchlist'
          : 'portfolio';
      return ['/topic/accounts/$accountId/market/quotes/$scope'];
    }
    if (stockCodes.isNotEmpty) {
      return stockCodes.map((code) => '/topic/market/stocks/$code').toList();
    }
    if (market != null && market!.isNotEmpty && market != 'ALL') {
      return ['/topic/market/markets/$market'];
    }
    return const ['/topic/market/quotes'];
  }
}

enum MarketQuoteAccountScope {
  watchlist,
  portfolio,
}

class MarketQuoteLiveClient {
  MarketQuoteLiveClient({
    required Uri baseUri,
    QuoteSocketConnector? socketConnector,
  })  : _baseUri = baseUri,
        _socketConnector =
            socketConnector ?? ((uri) => WebSocketQuoteSocketConnection(uri));

  final Uri _baseUri;
  final QuoteSocketConnector _socketConnector;

  Uri get webSocketUri {
    final scheme = _baseUri.scheme == 'https' ? 'wss' : 'ws';
    final normalizedBasePath = _baseUri.path.endsWith('/')
        ? _baseUri.path.substring(0, _baseUri.path.length - 1)
        : _baseUri.path;
    return _baseUri.replace(
      scheme: scheme,
      path: '$normalizedBasePath/ws/market',
      query: null,
    );
  }

  Stream<Map<String, dynamic>> subscribe(
    MarketQuoteLiveSubscription subscription,
  ) {
    final topics = subscription.topics;
    final connection = _socketConnector(webSocketUri);
    late final StreamSubscription<dynamic> socketSubscription;
    late final StreamController<Map<String, dynamic>> controller;

    void sendFrame(String command, Map<String, String> headers,
        [String? body]) {
      final buffer = StringBuffer(command)..write('\n');
      headers.forEach((key, value) {
        buffer.write('$key:$value\n');
      });
      buffer
        ..write('\n')
        ..write(body ?? '')
        ..write('\u0000');
      connection.add(buffer.toString());
    }

    void subscribeTopics() {
      for (var index = 0; index < topics.length; index += 1) {
        sendFrame('SUBSCRIBE', {
          'id': 'market-quote-$index',
          'destination': topics[index],
          'ack': 'auto',
        });
      }
    }

    void handleFrame(String frame) {
      if (frame.startsWith('CONNECTED')) {
        subscribeTopics();
        return;
      }
      if (!frame.startsWith('MESSAGE')) {
        return;
      }
      final separator = frame.indexOf('\n\n');
      if (separator < 0) {
        return;
      }
      final body = frame.substring(separator + 2).trim();
      if (body.isEmpty) {
        return;
      }
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        controller.add(decoded.map((key, value) => MapEntry('$key', value)));
      }
    }

    controller = StreamController<Map<String, dynamic>>(
      onListen: () {
        socketSubscription = connection.stream.listen(
          (event) {
            final payload = event is List<int>
                ? utf8.decode(event)
                : event?.toString() ?? '';
            for (final frame in payload.split('\u0000')) {
              if (frame.trim().isNotEmpty) {
                handleFrame(frame);
              }
            }
          },
          onError: controller.addError,
          onDone: controller.close,
        );
        sendFrame('CONNECT', {
          'accept-version': '1.2',
          'heart-beat': '10000,10000',
        });
      },
      onCancel: () async {
        await socketSubscription.cancel();
        await connection.close();
      },
    );

    return controller.stream;
  }
}
