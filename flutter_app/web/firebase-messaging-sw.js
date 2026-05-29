importScripts('https://www.gstatic.com/firebasejs/10.12.5/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.5/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCPbwCjZivExVMV6iJQvQLcnjAfr1m3CMA',
  authDomain: 'citoyen-peyi.firebaseapp.com',
  projectId: 'citoyen-peyi',
  storageBucket: 'citoyen-peyi.firebasestorage.app',
  messagingSenderId: '1087566305566',
  appId: '1:1087566305566:web:a199ae799558f6a324d10f',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function (payload) {
  const notification = payload.notification || {};
  const data = payload.data || {};
  const title = notification.title || 'Nouvelle consultation Citoyen Peyi';
  const options = {
    body: notification.body || 'Une consultation est ouverte dans votre commune.',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: data.pollId ? 'poll-' + data.pollId : 'citoyen-peyi-poll',
    data: data,
  };

  self.registration.showNotification(title, options);
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  event.waitUntil(clients.openWindow('/access-citizen'));
});