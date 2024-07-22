import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taskermg/common/dashboard.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/common/theme.dart';

class NotifiedPage extends StatelessWidget {
  final String? label;
  const NotifiedPage({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    var labelJsonDecoded = jsonDecode(label!);
    var title = "";

    //check type
    if (labelJsonDecoded['type'] != null) {
      if (labelJsonDecoded['type'] == 'error') {
        title = 'Error';
      } else if (labelJsonDecoded['type'] == 'success') {
        title = 'Success';
      } else if (labelJsonDecoded['type'] == 'invite') {
        title = 'Invitación';
        return Scaffold(
          body: Center(
            child: Container(
              height: 400,
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.8),
                    AppColors.secondaryColor.withOpacity(0.8)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¡Te han invitado a un proyecto!',
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: '',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textColor,
                      ),
                      children: [
                        TextSpan(
                          text: '${labelJsonDecoded['invitedBy']}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' te ha agregado al proyecto '),
                        TextSpan(
                          text: '${labelJsonDecoded['projectName']}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      MainController.setVar('onlyMine', true);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => Dashboard()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      primary: AppColors.primaryColor,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                    child: Text('Ver'),
                  ),
                ],
              ),
            ),
          ),
        );
      } else if (labelJsonDecoded['type'] == 'assign') {
        title = 'Asignacion';
        return Scaffold(
          body: Center(
            child: Container(
              height: 400,
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.8),
                    AppColors.secondaryColor.withOpacity(0.8)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¡Te han asignado una tarea!',
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: '',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textColor,
                      ),
                      children: [
                        TextSpan(
                          text: '${labelJsonDecoded['invitedBy']}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' te ha asignado la tarea '),
                        TextSpan(
                          text: '${labelJsonDecoded['taskName']}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' en el proyecto '),
                        TextSpan(
                          text: '${labelJsonDecoded['projectName']}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      MainController.setVar('onlyMine', true);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => Dashboard()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      primary: AppColors.primaryColor,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                    child: Text('Ver'),
                  ),
                ],
              ),
            ),
          ),
        );
      
      } else {
        title = 'Notification';
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Get.isDarkMode ? Colors.grey[600] : Colors.white,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios,
            color: Get.isDarkMode ? Colors.white : Colors.grey,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Center(
        child: Container(
          height: 400,
          width: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                AppColors.primaryColor.withOpacity(0.8),
                AppColors.backgroundColor.withOpacity(0.8)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Get.isDarkMode ? Colors.black : Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                labelJsonDecoded['title'] ?? 'Sin título',
                style: TextStyle(
                  fontSize: 18,
                  color: Get.isDarkMode ? Colors.black : Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                labelJsonDecoded['message'] ?? 'Sin mensaje',
                style: TextStyle(
                  fontSize: 16,
                  color: Get.isDarkMode ? Colors.black : Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
