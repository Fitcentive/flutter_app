importScripts('https://www.gstatic.com/firebasejs/8.4.1/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/8.4.1/firebase-messaging.js');

const firebaseConfig = {
    apiKey: "AIzaSyBLWpPaBj5uvuRaOev3SDB3zLW32WfupYU",
    authDomain: "fitcentive-dev-03.firebaseapp.com",
    projectId: "fitcentive-dev-03",
    storageBucket: "fitcentive-dev-03.appspot.com",
    messagingSenderId: "675708031489",
    appId: "1:675708031489:web:6757ea293a9cd20298a600"
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