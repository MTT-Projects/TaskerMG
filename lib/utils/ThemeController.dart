// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  // Reactive variables to hold the theme mode and colors
  var isDarkMode = true.obs;

  // Dark theme colors
  final darkPrimaryColor = Color(0xFF8A56AC);
  final darkSecondaryColor = Color(0xFFEE3D73);
  final darkBackgroundColor = Color(0xFF0E0E0E);
  final darkSecBackgroundColor = Color.fromRGBO(255, 255, 255, 1);
  final darkCardColor = Color(0xFF8A56AC);
  final darkTextColor = Color.fromRGBO(255, 255, 255, 1);
  final darkSecTextColor = Color(0xFF0E0E0E);
  final darkSubTextColor = Color(0xFFB3B3B3);

  // Light theme colors
  final lightPrimaryColor = Color(0xFF6200EA);
  final lightSecondaryColor = Color(0xFF03DAC6);
  final lightBackgroundColor = Color(0xFFFFFFFF);
  final lightSecBackgroundColor = Color(0xFF000000);
  final lightCardColor = Color(0xFFF1F1F1);
  final lightTextColor = Color(0xFF000000);
  final lightSecTextColor = Color.fromRGBO(255, 255, 255, 1);
  final lightSubTextColor = Color(0xFF757575);

  // Observable colors
  var primaryColor = Color(0xFF8A56AC).obs;
  var secondaryColor = Color(0xFFEE3D73).obs;
  var backgroundColor = Color(0xFF0E0E0E).obs;
  var secBackgroundColor = Color.fromRGBO(255, 255, 255, 1).obs;
  var cardColor = Color(0xFF8A56AC).obs;
  var textColor = Color(0xFFFFFFFF).obs;
  var secTextColor = Color(0xFF0E0E0E).obs;
  var subTextColor = Color(0xFFB3B3B3).obs;

  @override
  void onInit() {
    super.onInit();
    _updateThemeColors();
  }

  // Method to toggle theme mode
  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    _updateThemeColors();
  }

  // Update theme colors based on current mode
  void _updateThemeColors() {
    if (isDarkMode.value) {
      primaryColor.value = darkPrimaryColor;
      secondaryColor.value = darkSecondaryColor;
      backgroundColor.value = darkBackgroundColor;
      secBackgroundColor.value = darkSecBackgroundColor;
      cardColor.value = darkCardColor;
      textColor.value = darkTextColor;
      secTextColor.value = darkSecTextColor;
      subTextColor.value = darkSubTextColor;
    } else {
      primaryColor.value = lightPrimaryColor;
      secondaryColor.value = lightSecondaryColor;
      backgroundColor.value = lightBackgroundColor;
      secBackgroundColor.value = lightSecBackgroundColor;
      cardColor.value = lightCardColor;
      textColor.value = lightTextColor;
      secTextColor.value = lightSecTextColor;
      subTextColor.value = lightSubTextColor;
    }
  }
}
