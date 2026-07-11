import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class IosPushTokenProvider {
  const IosPushTokenProvider();

  static const _channel = MethodChannel('com.hanaharmony.stockexchange/push');

  Future<String?> requestToken() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return null;
    }
    try {
      final token = await _channel.invokeMethod<String>('requestPushToken');
      final normalized = token?.trim() ?? '';
      return normalized.isEmpty ? null : normalized;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
