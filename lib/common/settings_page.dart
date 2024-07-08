import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:taskermg/common/theme.dart';
import 'package:taskermg/services/theme_services.dart';

class SettingsScr extends StatefulWidget {
  const SettingsScr({super.key});

  @override
  State<SettingsScr> createState() => _SettingsScrState();
}

class _SettingsScrState extends State<SettingsScr> {
  final ThemeServices _themeController = Get.put(ThemeServices());
  bool _giveVerse = ThemeServices().isDark; // Define the _giveVerse variable
  @override
  Widget build(BuildContext context) {
    return Center(
      //switch para cambiar el tema del sistema
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('Dark Mode', style: titleStyle),
            CupertinoSwitch(
              value: _giveVerse,
              onChanged: (bool value) {
                //cambiar el tema del sistema
                _themeController.switchTheme();
                setState(() {
                  _giveVerse = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
