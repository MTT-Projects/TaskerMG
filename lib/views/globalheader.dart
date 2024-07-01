import 'package:dos/common/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../common/pages/profile.dart';
import '../services/theme_services.dart';

AppBar globalheader(bg, title, {icon = Icons.question_answer_rounded}) {
  return AppBar(
    elevation: 0,
    backgroundColor: bg,
    //Titulo segun la seccion
    title: Text(
      title,
      style: GoogleFonts.lato(
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    leading: GestureDetector(
        onTap: () {
          ThemeServices().switchTheme();
                // notifyHelper.scheduledNotification();
        },
        child: Icon(
          Get.isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
          size: 20,
          color: Get.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    actions: [
      GestureDetector(
        onTap: () {
          Get.to(() => const ProfilePage());
        },
        child: FloatingActionButton(
          onPressed: () async {
            print('Menu');  
            Get.to(() => const ProfilePage());
          },
          backgroundColor: Colors.transparent,
          child: const Icon(Icons.menu, color: Colors.white, size: 30,),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          )
        ),
      ),
    ],
  );
}
