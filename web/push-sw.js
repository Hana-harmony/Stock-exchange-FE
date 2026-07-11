self.addEventListener('push', (event) => {
  let payload = {};
  try {
    payload = event.data ? event.data.json() : {};
  } catch (_) {
    payload = {notification: {title: 'Hana Local Exchange', body: event.data?.text() || ''}};
  }
  const notification = payload.notification || payload;
  const data = payload.data || notification.data || {};
  event.waitUntil(self.registration.showNotification(
    notification.title || 'Hana Local Exchange',
    {
      body: notification.body || '',
      data,
      tag: data.notificationId || data.eventId || undefined,
      renotify: false,
    },
  ));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil((async () => {
    const clientsList = await self.clients.matchAll({type: 'window', includeUncontrolled: true});
    for (const client of clientsList) {
      if ('focus' in client) {
        return client.focus();
      }
    }
    return self.clients.openWindow('./');
  })());
});
