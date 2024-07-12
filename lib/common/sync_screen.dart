// ignore_for_file: prefer_const_constructors, prefer_final_fields, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:taskermg/common/dashboard.dart';
import 'package:taskermg/common/theme.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/utils/sync/sync_projects.dart';
import 'package:taskermg/utils/sync/sync_tasks.dart';
import 'package:taskermg/utils/sync/sync_user_projects.dart';
import 'package:taskermg/utils/AppLog.dart';
import 'package:taskermg/utils/sync/sync_projects.dart';
import 'package:taskermg/utils/sync/sync_tasks.dart';
import 'package:taskermg/utils/sync/sync_user_projects.dart';
import '../controllers/sync_controller.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  String _message = 'Sincronizando información...';
  SyncController syncController = SyncController();
  double _progress = 0.0;
  List<String> _syncSteps = [
    'Sincronizando proyectos...',
    'Sincronizando tareas...',
    'Sincronizando relaciones...',
    // Agrega más pasos de sincronización aquí
  ];

  @override
  void initState() {
    super.initState();
    syncData();
  }

  Future<void> syncData() async {
    var userID = MainController.getVar('currentUser');
    AppLog.d('Iniciando sincronización de datos de usuario: $userID');

    for (int i = 0; i < _syncSteps.length; i++) {
      setNewMessage(_syncSteps[i]);
      await _performSyncStep(i, userID);
      setProgress((i + 1) / _syncSteps.length);
    }

    setNewMessage('Sincronización completa.');
    await Future.delayed(
        Duration(seconds: 2)); // Esperar 2 segundos antes de continuar
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Dashboard()),
    );
  }

  Future<void> _performSyncStep(int stepIndex, dynamic userID) async {
    switch (stepIndex) {
      case 0:
        await SyncProjects.pullProjects();
        await SyncProjects.pushProjects();
        break;
      case 1:
        await SyncTasks.pullTasks();
        await SyncTasks.pushTasks();
        break;
      case 2:
        await SyncUserProjects.pullUserProjects();
        await SyncUserProjects.pushUserProjects();
        break;
      // Agrega más casos para otros pasos de sincronización
    }
  }

  void setNewMessage(String message) {
    setState(() {
      _message = message;
    });
  }

  void setProgress(double progress) {
    setState(() {
      _progress = progress;
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
            SizedBox(height: 20),
            // Progress indicator
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey,
              color: AppColors.primaryColor,
            ),
            SizedBox(height: 20),
            // Button to continue
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
