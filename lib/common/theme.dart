// ignore_for_file: prefer_const_constructors, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// Nuevos colores
const Color darkPrimaryColor = Color.fromRGBO(90, 87, 255, 1);
const Color darkSecondaryColor = Color.fromRGBO(158, 0, 109, 1);
const Color darkBackgroundColor = Color.fromRGBO(14, 14, 14, 1);
const Color darkBackgroundColor2 = Color.fromRGBO(10, 10, 10, 1);
const Color darkSecBackgroundColor = Color.fromRGBO(255, 255, 255, 1);
const Color darkCardColor = Color.fromRGBO(138, 86, 172, 1);
const Color darkTextColor = Color.fromRGBO(255, 255, 255, 1);
const Color darkSecTextColor = Color.fromRGBO(14, 14, 14, 1);
const Color darkSubTextColor = Color.fromRGBO(179, 179, 179, 1);

const Color lightPrimaryColor = Color.fromRGBO(98, 0, 234, 1);
const Color lightSecondaryColor = Color.fromRGBO(3, 218, 198, 1);
const Color lightBackgroundColor = Color.fromRGBO(255, 255, 255, 1);
const Color lightBackgroundColor2 = Color.fromRGBO(250, 250, 250, 1);
const Color lightSecBackgroundColor = Color.fromRGBO(0, 0, 0, 1);
const Color lightCardColor = Color.fromRGBO(241, 241, 241, 1);
const Color lightTextColor = Color.fromRGBO(0, 0, 0, 1);
const Color lightSecTextColor = Color.fromRGBO(255, 255, 255, 1);
const Color lightSubTextColor = Color.fromRGBO(117, 117, 117, 1);

// Colores existentes
const Color bluishClr = Color.fromRGBO(78, 90, 232, 1);
const Color bluefaded = Color.fromRGBO(133, 181, 221, 1);
const Color yellowClr = Color.fromRGBO(255, 183, 70, 1);
const Color pinkClr = Color.fromRGBO(255, 70, 103, 1);
const Color white = Color.fromRGBO(255, 255, 255, 1);
//const Color primaryClr = bluishClr;
const Color darkGreyClr = Color.fromRGBO(18, 18, 18, 1);
const Color darkHeaderClr = Color.fromRGBO(66, 66, 66, 1);

class AppColors {
  static Color errorColor = Colors.red;

  static Color get primaryColor => Get.isDarkMode ? darkPrimaryColor : lightPrimaryColor;
  static Color get secondaryColor => Get.isDarkMode ? darkSecondaryColor : lightSecondaryColor;
  static Color get backgroundColor => Get.isDarkMode ? darkBackgroundColor : lightBackgroundColor;
  static Color get backgroundColor2 => Get.isDarkMode ? darkBackgroundColor2 : lightBackgroundColor2;
  static Color get secBackgroundColor => Get.isDarkMode ? darkSecBackgroundColor : lightSecBackgroundColor;
  static Color get cardColor => Get.isDarkMode ? darkCardColor : lightCardColor;
  static Color get textColor => Get.isDarkMode ? darkTextColor : lightTextColor;
  static Color get secTextColor => Get.isDarkMode ? darkSecTextColor : lightSecTextColor;
  static Color get subTextColor => Get.isDarkMode ? darkSubTextColor : lightSubTextColor;
}

class AppTextStyle{
  static TextStyle get style14wNormalBlueButton => GoogleFonts.lato(
    textStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: bluishClr,
    )
  );

  static TextStyle get style14wBlueButton => GoogleFonts.lato(
    textStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: bluishClr,
    )
  );
}
class Themes {
  static final light = ThemeData(
    backgroundColor: AppColors.backgroundColor,
    primaryColor: AppColors.primaryColor,
    primaryColorDark: Color.fromRGBO(255, 255, 255, 1),
    primaryColorLight: Color.fromRGBO(0, 0, 0, 1),
    brightness: Brightness.light,
    cardColor: AppColors.cardColor,
    textTheme: TextTheme(
      bodyText1: TextStyle(color: AppColors.textColor),
      bodyText2: TextStyle(color: AppColors.subTextColor),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: lightBackgroundColor,
      hourMinuteTextColor: lightPrimaryColor,
      hourMinuteColor: lightPrimaryColor.withOpacity(0.12),
      dayPeriodTextColor: lightSecondaryColor,
      dayPeriodColor: lightSecondaryColor.withOpacity(0.12),
      dialHandColor: lightPrimaryColor,
      dialBackgroundColor: lightPrimaryColor.withOpacity(0.12),
      dialTextColor: MaterialStateColor.resolveWith((states) =>
        states.contains(MaterialState.selected) ? lightTextColor : lightPrimaryColor),
      entryModeIconColor: lightPrimaryColor,
      hourMinuteTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: lightPrimaryColor),
      dayPeriodTextStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: lightSecondaryColor),
      helpTextStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: lightPrimaryColor),
    ),
  );

  static final dark = ThemeData(
    backgroundColor: AppColors.backgroundColor,
    primaryColor: AppColors.primaryColor,
    primaryColorDark: Color.fromRGBO(0, 0, 0, 1),
    primaryColorLight: Color.fromRGBO(255, 255, 255, 1),
    brightness: Brightness.dark,
    cardColor: AppColors.cardColor,
    textTheme: TextTheme(
      bodyText1: TextStyle(color: AppColors.textColor),
      bodyText2: TextStyle(color: AppColors.subTextColor),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: darkBackgroundColor,
      hourMinuteTextColor: darkTextColor,
      hourMinuteColor: darkPrimaryColor.withOpacity(0.12),
      dayPeriodTextColor: darkSecondaryColor,
      dayPeriodColor: darkSecondaryColor.withOpacity(0.12),
      dialHandColor: darkPrimaryColor,
      dialBackgroundColor: darkPrimaryColor.withOpacity(0.12),
      dialTextColor: MaterialStateColor.resolveWith((states) =>
        states.contains(MaterialState.selected) ? darkTextColor : darkPrimaryColor),
      entryModeIconColor: darkPrimaryColor,
      hourMinuteTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkTextColor),
      dayPeriodTextStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: darkSecondaryColor),
      helpTextStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: darkPrimaryColor),
    ),
  );
}

TextStyle get subHeadingStyle {
  return GoogleFonts.lato(
      textStyle: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Get.isDarkMode ? Color.fromRGBO(169, 169, 169, 1) : Color.fromRGBO(169, 169, 169, 1),
  ));
}

TextStyle get headingStyle {
  return GoogleFonts.lato(
      textStyle: TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    color: Get.isDarkMode ? Color.fromRGBO(255, 255, 255, 1) : Color.fromRGBO(0, 0, 0, 1),
  ));
}

TextStyle get headingStyleInv {
  return GoogleFonts.lato(
      textStyle: TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    color: Get.isDarkMode ? Color.fromRGBO(0, 0, 0, 1) : Color.fromRGBO(255, 255, 255, 1),
  ));
}

TextStyle get titleStyle {
  return GoogleFonts.lato(
      textStyle: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Get.isDarkMode ? Color.fromRGBO(255, 255, 255, 1) : Color.fromRGBO(0, 0, 0, 1),
  ));
}

TextStyle get subTitleStyle {
  return GoogleFonts.lato(
      textStyle: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Get.isDarkMode ? Color.fromRGBO(255, 255, 255, 1) : Color.fromRGBO(96, 96, 96, 1),
  ));
}

ThemeData get lightDatePickerTheme {
    return ThemeData.light().copyWith(
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryColor,
        onPrimary: Colors.white,
        surface: AppColors.cardColor,
        onSurface: Colors.black,
      ),
      dialogBackgroundColor: AppColors.backgroundColor,
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(primary: AppColors.primaryColor),
      ),
    );
  }

  ThemeData get darkDatePickerTheme {
    return ThemeData.dark().copyWith(
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryColor,
        onPrimary: Colors.white,
        surface: AppColors.cardColor,
        onSurface: Colors.white,
      ),
      dialogBackgroundColor: AppColors.backgroundColor,
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(primary: AppColors.primaryColor),
      ),
    );
  }