// ignore_for_file: import_of_legacy_library_into_null_safe, unused_import

import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:taskermg/services/notification_services.dart';
import 'package:taskermg/utils/AppLog.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:taskermg/firebase_options.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/servicecontrol/v1.dart' as servicecontrol;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  AppLog.d('Handling a background message ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
}

class FirebaseApi {
  static final firebaseMessaging = FirebaseMessaging.instance;
  NotifyHelper notifyHelper = NotifyHelper();

  Future<void> initNotifications() async {
    await dotenv.load();

    notifyHelper = NotifyHelper();
    notifyHelper.initializeNotification();
    notifyHelper.requestIOSPermissions();

    NotificationSettings settings = await firebaseMessaging.requestPermission(
      alert: dotenv.env['FIREBASE_NOTIFICATION_ALERT'] == 'true',
      announcement: dotenv.env['FIREBASE_NOTIFICATION_ANNOUNCEMENT'] == 'true',
      badge: dotenv.env['FIREBASE_NOTIFICATION_BADGE'] == 'true',
      carPlay: dotenv.env['FIREBASE_NOTIFICATION_CAR_PLAY'] == 'true',
      criticalAlert: dotenv.env['FIREBASE_NOTIFICATION_CRITICAL_ALERT'] == 'true',
      provisional: dotenv.env['FIREBASE_NOTIFICATION_PROVISIONAL'] == 'true',
      sound: dotenv.env['FIREBASE_NOTIFICATION_SOUND'] == 'true',
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
      //send local notification
      notifyHelper.displayNotification(
        title: message.notification?.title ?? "Title",
        body: message.notification?.body ?? "",
        payload: jsonEncode(message.data),
      );
    });
  }

  static Future<String> getAccessToken() async {
    await dotenv.load();

    final serviceAccountJson = {
      "type": "service_account",
      "project_id": dotenv.env['FIREBASE_PROJECT_ID'],
      "private_key_id": dotenv.env['FIREBASE_PRIVATE_KEY_ID'],
      "private_key": dotenv.env['FIREBASE_PRIVATE_KEY'],
      "client_email": dotenv.env['FIREBASE_CLIENT_EMAIL'],
      "client_id": dotenv.env['FIREBASE_CLIENT_ID'],
      "auth_uri": dotenv.env['FIREBASE_AUTH_URI'],
      "token_uri": dotenv.env['FIREBASE_TOKEN_URI'],
      "auth_provider_x509_cert_url": dotenv.env['FIREBASE_AUTH_PROVIDER_X509_CERT_URL'],
      "client_x509_cert_url": dotenv.env['FIREBASE_CLIENT_X509_CERT_URL'],
    };

    List<String> scopes = [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/firebase.messaging',
      'https://www.googleapis.com/auth/cloud-platform',
    ];

    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );

    auth.AccessCredentials credentials =
        await auth.obtainAccessCredentialsViaServiceAccount(
            auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
            scopes,
            client);

    client.close();
    return credentials.accessToken.data;
  }

  static Future<void> sendNotification({
    required String to,
    required String title,
    required String body,
    required Map<String, dynamic>? data,
  }) async {
    final String serverAccessToken = await getAccessToken();
    String endpointFirebaseCloudMessaging = dotenv.env['FIREBASE_CLOUD_MESSAGING_ENDPOINT'] ?? '';

    final Map<String, dynamic> message = {
      'message': {
        'token': to,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data,
      }
    };

    final response = await http.post(
      Uri.parse(endpointFirebaseCloudMessaging),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverAccessToken',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('Message sent successfully');
    } else {
      print('Message failed to send');
      print(response.body);
    }
  }
}
