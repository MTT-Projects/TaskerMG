import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:taskermg/common/theme.dart'; // Asegúrate de importar tu archivo de tema

class NoInternetScr extends StatefulWidget {
  const NoInternetScr({super.key});

  @override
  State<NoInternetScr> createState() => _NoInternetScrState();
}

class _NoInternetScrState extends State<NoInternetScr> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'Assets/lottie/noConnection.json',
              width: 200,
              height: 200,
            ),
            SizedBox(height: 20),
            Text(
              'No hay conexión a internet',
              style: TextStyle(
                color: AppColors.primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Acción para intentar reconectar
              },
              style: ElevatedButton.styleFrom(
                primary: AppColors.secondaryColor, // Fondo del botón
                onPrimary: Colors.white, // Color del texto
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Reintentar',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
