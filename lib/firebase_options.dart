import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCyVmZ535Vd9U9EOC-gKywm7ITri_YCfu4',
    appId: '1:581635607729:android:34b5bc48fae450997d2690',
    messagingSenderId: '581635607729',
    projectId: 'church-mobile-a1758',
    authDomain: 'church-mobile-a1758.firebaseapp.com',
    storageBucket: 'church-mobile-a1758.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCyVmZ535Vd9U9EOC-gKywm7ITri_YCfu4',
    appId: '1:581635607729:android:34b5bc48fae450997d2690',
    messagingSenderId: '581635607729',
    projectId: 'church-mobile-a1758',
    storageBucket: 'church-mobile-a1758.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCyVmZ535Vd9U9EOC-gKywm7ITri_YCfu4',
    appId: '1:581635607729:android:34b5bc48fae450997d2690',
    messagingSenderId: '581635607729',
    projectId: 'church-mobile-a1758',
    storageBucket: 'church-mobile-a1758.firebasestorage.app',
    iosClientId: '581635607729-xxxxx.apps.googleusercontent.com',
    iosBundleId: 'com.example.church_mobile',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCyVmZ535Vd9U9EOC-gKywm7ITri_YCfu4',
    appId: '1:581635607729:android:34b5bc48fae450997d2690',
    messagingSenderId: '581635607729',
    projectId: 'church-mobile-a1758',
    storageBucket: 'church-mobile-a1758.firebasestorage.app',
    iosClientId: '581635607729-xxxxx.apps.googleusercontent.com',
    iosBundleId: 'com.example.church_mobile',
  );
}
