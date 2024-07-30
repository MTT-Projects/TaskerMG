import 'package:firebase_core/firebase_core.dart';

import 'package:taskermg/common/widgets/splash.dart';
import 'package:taskermg/controllers/sync_controller.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/services/theme_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'common/theme.dart';
import 'utils/AppLog.dart';
import 'api/firebase_api.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await DBHelper.initialize();
  AppLog.d("DB initialized");
  var localdb = await LocalDB.initDb();
  var str = localdb.toString();
  AppLog.d("Local DB initialized as ${localdb}");

  await Firebase.initializeApp();
  await FirebaseApi().initNotifications();
    
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TaskerMG',
      theme: Themes.light,
      darkTheme: Themes.dark,
      themeMode: ThemeServices().theme,
      home: const Splash(
          //title: 'Meselal',
          ),
    );
  }
}
