import 'package:taskermg/common/widgets/splash.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/services/theme_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'common/theme.dart';
import 'utils/AppLog.dart';
import 'controllers/maincontroller.dart';

MainController MC = MainController();
Future<void> main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await DBHelper.initialize();
  AppLog.d("DB initialized");
  var localdb = await LocalDB.initDb();
  var str = localdb.toString();
  AppLog.d("Local DB initialized as {}");
  MC.setVar('currentProject', 2);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meselal',
      theme: Themes.light,
      darkTheme: Themes.dark,
      themeMode: ThemeServices().theme,
      home: const Splash(
          //title: 'Meselal',
          ),
    );
  }
}
