import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:poster/startup/presentation/onboarding.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/colors.dart';
import 'core/network/local_storage.dart';
import 'core/shared_components.dart';
import 'features/auth/data/auth.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/dashboard/presentation/dashboard.dart';

// Global variable to handle background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages - this runs in a separate isolate
  print("Handling a background message: ${message.messageId}");

  // You can show local notification here using flutter_local_notifications
  // or handle the message data as needed
  if (message.notification != null) {
    print('Background Notification: ${message.notification?.title}');
    print('Background Notification: ${message.notification?.body}');
  }
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Janasena Poster',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: SharedColors.primary),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const _Home(),
        '/dashboard': (context) => const Dashboard(),
      },
    );
  }
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  String? authToken;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    checkAuthStatus();
    _checkAndRequestPermissions();
    _setupFirebaseMessaging();
  }

  Future<void> _setupFirebaseMessaging() async {
    // Request permission for notifications (required for Android 13+)
    if (Platform.isAndroid) {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('User granted permission: ${settings.authorizationStatus}');
    }

    // Get the FCM token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Save token to shared preferences or send to your server
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('fcm_token', token);
      print('FCM token saved: $token');
    }

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('FCM Token refreshed: $newToken');
      // Update token on your server
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('fcm_token', newToken);
      });
    });

    // Handle foreground messages (app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // Show local notification using flutter_local_notifications or custom dialog
        _showLocalNotification(message);
      }
    });

    // Handle notification clicks when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked when app was in background: ${message.messageId}');
      _handleNotificationClick(message);
    });

    // Handle initial notification when app is launched from terminated state
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('App launched from terminated state by notification: ${initialMessage.messageId}');
      _handleNotificationClick(initialMessage);
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    // You can use flutter_local_notifications package for better notification handling
    // For now, we'll just log the notification
    print('Showing notification: ${message.notification?.title} - ${message.notification?.body}');

    // Alternatively, show a dialog or snackbar for foreground notifications
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.notification?.title ?? 'New Notification'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    // Handle notification click - navigate to specific screen based on message data
    print('Notification clicked with data: ${message.data}');

    // Example: Navigate to specific screen based on message data
    // if (message.data['type'] == 'news') {
    //   Navigator.pushNamed(context, '/news');
    // }
  }

  Future<void> _checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      await [
        Permission.storage,
        Permission.photos,
        if (await Permission.manageExternalStorage.isRestricted)
          Permission.manageExternalStorage,
        Permission.notification, // Add notification permission
      ].request();
    }
  }

  Future<void> checkAuthStatus() async {
    authToken = await getToken();
    FlutterNativeSplash.remove();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (authToken != null && authToken!.isNotEmpty) {
      return const Dashboard();
    }

    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Placeholder();
        }

        SharedPreferences preferences = snapshot.data!;
        String? status = preferences.getString("status");

        return MultiProvider(
          providers: [
            Provider(create: (context) => Auth(preferences)),
            Provider(create: (context) => preferences),
          ],
          builder: (context, child) {
            if (status == null) {
              return SharedComponents.scaffolded(const OnboardingPage());
            }
            if (status == AuthState.loggedOut.name) {
              return SharedComponents.scaffolded(const AuthScreen());
            }
            return const Dashboard();
          },
        );
      },
    );
  }
}