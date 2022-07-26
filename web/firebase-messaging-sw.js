importScripts('https://www.gstatic.com/firebasejs/8.4.1/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/8.4.1/firebase-messaging.js');

const firebaseConfig = {
    apiKey: "AIzaSyBK6_1sXpa-BnTtAZw2uKmVsYuQQoupL7Y",
    authDomain: "fitcentive-1210.firebaseapp.com",
    projectId: "fitcentive-1210",
    storageBucket: "fitcentive-1210.appspot.com",
    messagingSenderId: "211948202240",
    appId: "1:211948202240:web:cce838d44ee7831942ebe5",
    measurementId: "G-MZ4R425SMP"
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();
messaging.setBackgroundMessageHandler(function (payload) {
    const promiseChain = clients
        .matchAll({
            type: "window",
            includeUncontrolled: true
        })
        .then(windowClients => {
            for (let i = 0; i < windowClients.length; i++) {
                const windowClient = windowClients[i];
                windowClient.postMessage(payload);
            }
        })
        .then(() => {
            return registration.showNotification("New Message");
        });
    return promiseChain;
});

messaging.onBackgroundMessage(function(payload) {
    console.log('Received background message ', payload);

    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
    };

    self.registration.showNotification(notificationTitle,
        notificationOptions);
});

self.addEventListener('notificationclick', function (event) {
    console.log('notification received: ', event)
});