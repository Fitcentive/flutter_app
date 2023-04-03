importScripts('https://www.gstatic.com/firebasejs/8.4.1/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/8.4.1/firebase-messaging.js');

const firebaseConfig = {
    apiKey: "AIzaSyBnVD5q4IRi2LTZuGMPg5LPAwqRHDjMBug",
    authDomain: "fitcentive-dev-02.firebaseapp.com",
    projectId: "fitcentive-dev-02",
    storageBucket: "fitcentive-dev-02.appspot.com",
    messagingSenderId: "27981216008",
    appId: "1:27981216008:web:442a225e58f2cd4dd954bd"
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