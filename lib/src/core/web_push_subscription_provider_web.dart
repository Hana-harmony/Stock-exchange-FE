import 'dart:js_interop';

const _vapidPublicKey = String.fromEnvironment(
  'WEB_PUSH_VAPID_PUBLIC_KEY',
);

@JS('hanaWebPush.isSupported')
external bool _isWebPushSupported();

@JS('hanaWebPush.getExistingSubscription')
external JSPromise<JSString?> _getExistingSubscription();

@JS('hanaWebPush.requestSubscription')
external JSPromise<JSString?> _requestSubscription(JSString vapidPublicKey);

class WebPushSubscriptionProvider {
  const WebPushSubscriptionProvider();

  bool get isSupported => _vapidPublicKey.isNotEmpty && _isWebPushSupported();

  Future<String?> currentSubscription() async {
    if (!isSupported) {
      return null;
    }
    final value = await _getExistingSubscription().toDart;
    return value?.toDart;
  }

  Future<String?> requestSubscription() async {
    if (!isSupported) {
      return null;
    }
    final value = await _requestSubscription(_vapidPublicKey.toJS).toDart;
    return value?.toDart;
  }
}
