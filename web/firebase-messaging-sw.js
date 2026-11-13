// Firebase Cloud Messaging service worker for the web build.
// Registered by firebase_messaging on getToken(). Shows pushes while the app
// tab is closed or in the background; a click opens the link that send-push
// puts in webpush.fcm_options.link. The config below is the public web app
// config (same as lib/firebase_options.dart), not a secret.
// Keep the SDK version in step with firebase_core_web's
// supportedFirebaseJsSdkVersion.
importScripts('https://www.gstatic.com/firebasejs/13.1.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/13.1.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAgIpx-j5CNTHDlykppl8-uIQPRBw1eKgw',
  appId: '1:1045113970057:web:451a3abef9daa3519b5558',
  messagingSenderId: '1045113970057',
  projectId: 'efs-tickets',
  authDomain: 'efs-tickets.firebaseapp.com',
  storageBucket: 'efs-tickets.firebasestorage.app',
});

firebase.messaging();
