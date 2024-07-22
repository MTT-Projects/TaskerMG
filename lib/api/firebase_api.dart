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
    notifyHelper = NotifyHelper();
    notifyHelper.initializeNotification();
    notifyHelper.requestIOSPermissions();

    NotificationSettings settings = await firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
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
    final serviceAccoundJson = {
      "type": "service_account",
      "project_id": "taskermg-e2001",
      "private_key_id": "a6f5550da1c97ef9b19253708d78e33be1d73ac5",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDAQECfMMdIMV9j\nW9XqOFRGbPPYbGcbhdDtA7SHmxZ4bt72nIK4KaH+gKxI7yz/rAXoifiqga/1afUL\nEgbd4USpzharLQ2OZ4pwFN7KL0Vh9pkpJXg1R/lxDjwTILLiy4WmoNTMYVABBejz\nGEqQsY5Z3yYYLBDoEH9f1d6KFtcmgFGVdpnkB5onaexkPyuLcwx52W7BkM3gX8oI\n2/GmvYnjDAUlls1QOVb3b0SkVVKGMISbl9m9sLDDz4qDW1CXjdewqHj9Q4bF1KX5\nMM3kFPBjwTb9lhMzIHo+TUvaENcLW/jfSxKkpYCnBzKG6tk/jEYGbw21W24+2UqY\n2hzC4+SxAgMBAAECggEANl21KI9du4+ivvFIc/zL8EJ9TpWRLtpPs8bZdYOo/hO0\nX57w5G15jwQKNHHWktKttQ3XUThtbwQwtJm7cWFzzmUmSe/qpnunTXzJZ/moMETR\nGS6saLza0FrLKEmV7MbLG8zdgJKAUlm+f4g+Bd8AN3AAUNOdUFLiAlLzpK9C1nLz\nozKH0l186ReiIn9em6tZMYHQcvNoDrt02Gs4yYO5Uul4sHFTTPSVy10G9qRWdo12\nXxUHV3BuJuAeKZ3yUKIAEHrs4dm4m3aHy58AVBsc17wCeVhkIxv7zkEQ+0f1EpKp\nBK6l9+UVNkdNn2V0MVM7S+nAd/ZfYRjeZ1+bwN+/NQKBgQDg5txVYi60+7nNzpQk\nAdqfkvJUySvMuZ35ioNVa0KZqjFwqDknAIMoDANtEZk+hJQ0/1YAuLOqSgrUqb4q\nc2zkkVkunMScNbnvf+QpfaOrc5RUZqsxLyUS7kLqbFy3VfJqSeeJkrnmhJMyWjzB\nL5Wx3y2R/evap8jSyT5/rK2DRwKBgQDa1ZvXkF/cMqf3b6zBL7Mg0iQypNcro41f\nHdUXi+E6MmDWBU0h8w3migbgfL1qpOlHd4W71uytFhMnrKoJovF94g/pG4SkdVil\nyQ9BzNHdnhlu6bOtvU/i4dq8UIfuOPH+3cZKcoBh8AAN1wX6r0rmU3ieys3cVnTi\nDwmz+32kRwKBgElXf+roRcsHfCQ9hdnoMN9xEE3N/NaagYXrQcENZX6vHchbU6gA\nZsUchdF/t7XHjn1p9yXtFcomszl+0WEOmyg+rhKhVQyMCMKttj5BlqpG2sxbXuB/\nO1vdDz1bcTDoelFnIHagvrcJ7OayvrVRS0PiP/4oDE4WAUucDSGdskfpAoGBAKE3\nBuVq9kQJiZaPTgzQcD24snQg3mfGyMqO9sKvCVFPdemV5DojjlUN0H0nSIA9V6KP\n2hUFBD2Larcqy+XnhdNAbIpF/JUP4ivYkIXgN6f15jTAtN9E/Ype6z8acNm+WAF0\nLrX/3rbIEbIge8Yvx5UhX1ZUgA5YHym+/F3845XXAoGANjLtoh8/aotFICnJgwiA\nSepGm/XZZf96lof0aSoYZlLx9fqAiSp7hcIFlwCOKbrK7b6EffagOABRspZlSkj4\nnBXVlIDivJQ5bUHVT2d/X6ja3r7pQmABMfIBVVHC8y0hm1JGULFUpF3LmY3FCFN8\nuMoC1oq4KOXyvOTzKwuytCk=\n-----END PRIVATE KEY-----\n",
      "client_email": "taskermg-e2001@appspot.gserviceaccount.com",
      "client_id": "106389365642266119493",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/taskermg-e2001%40appspot.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };

    List<String> scopes = [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/firebase.messaging',
      'https://www.googleapis.com/auth/cloud-platform',
    ];

    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccoundJson),
      scopes,
    );

    auth.AccessCredentials credentials =
        await auth.obtainAccessCredentialsViaServiceAccount(
            auth.ServiceAccountCredentials.fromJson(serviceAccoundJson),
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
    String endpointFirebaseCloudMesssaging =
        'https://fcm.googleapis.com/v1/projects/taskermg-e2001/messages:send';

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
      Uri.parse(endpointFirebaseCloudMesssaging),
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
