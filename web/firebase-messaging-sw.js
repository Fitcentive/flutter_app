importScripts('https://www.gstatic.com/firebasejs/8.4.1/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/8.4.1/firebase-messaging.js');

const firebaseConfig = {
    apiKey: "AIzaSyBLKAtbshtA2-0_Ki_YQKsfUhUAGg0jmMk",
    authDomain: "fitcentive-dev.firebaseapp.com",
    projectId: "fitcentive-dev",
    storageBucket: "fitcentive-dev.appspot.com",
    messagingSenderId: "823597371065",
    appId: "1:823597371065:web:aa8d8365aefaf5c1671568"
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