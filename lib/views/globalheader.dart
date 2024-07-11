import 'package:taskermg/common/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/theme_services.dart';

import '../common/pages/profile.dart';
import '../services/theme_services.dart';

AppBar globalheader(bg, title, {icon = Icons.question_answer_rounded}) {
  ThemeServices _themeServices = ThemeServices();
  return AppBar(
    elevation: 0,
    backgroundColor: AppColors.secBackgroundColor,
    //Titulo segun la seccion
    title: Text(
      title,
      style: headingStyleInv,
    ),
    shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25)),
            ),
    actions: [
      GestureDetector(
        onTap: () {
          Get.to(() => const ProfilePage());
        },
        child: IconButton(
          onPressed: () async {
            print('Menu');
            Get.to(() => const ProfilePage());
          },
          icon: Icon(
            Icons.edit,
            color: _themeServices.isDark ? Colors.black : Colors.white,
            size: 30,
          ),
        ),
      )
    ],
    iconTheme: IconThemeData(
    color: _themeServices.isDark ? Colors.black : Colors.white,
  ),
  );
}
