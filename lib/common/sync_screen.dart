// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:taskermg/common/dashboard.dart';
import 'package:taskermg/common/theme.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/utils/AppLog.dart';
import '../controllers/sync_controller.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  String _message = 'Sincronizando información...';
  SyncController syncController = SyncController();
  MainController MC = MainController();

  @override
  void initState() {
    super.initState();
    syncData();
  }

  Future<void> syncData() async {
    var userID = MC.getVar('userID');
    AppLog.d('Iniciando sincronización de datos de usuario: $userID');
    setNewMessage('Sincronizando proyectos...');
    await syncController.syncProjects(userID);
    
    setNewMessage('Sincronizando tareas...');
    await syncController.syncTasks(userID);

    setNewMessage('Sincronizando relaciones...');
    await syncController.syncRelations(userID);
    

    // Agrega más llamadas de sincronización aquí si es necesario

    setNewMessage('Sincronización completa.');
    await Future.delayed(Duration(seconds: 2)); // Esperar 2 segundos antes de continuar


  }

  void setNewMessage(String message) {
    setState(() {
      _message = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie animation
            Container(
              child: Lottie.asset(
                'Assets/lotties/syncData2.json', // Asegúrate de tener el archivo Lottie en esta ruta
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 20),
            // Loading text
            Text(
              _message,
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            //button continue
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Dashboard()),
                );
              },
              child: Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
