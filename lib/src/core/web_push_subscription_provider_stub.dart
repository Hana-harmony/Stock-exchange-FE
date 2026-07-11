class WebPushSubscriptionProvider {
  const WebPushSubscriptionProvider();

  bool get isSupported => false;

  Future<String?> currentSubscription() async => null;

  Future<String?> requestSubscription() async => null;
}
