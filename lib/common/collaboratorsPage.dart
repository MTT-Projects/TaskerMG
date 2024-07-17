import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taskermg/controllers/collaboratorsController.dart';
import 'package:taskermg/controllers/conecctionChecker.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/models/project.dart';
import 'package:taskermg/utils/AppLog.dart';
import '../models/user.dart';
import 'package:taskermg/common/widgets/noInternet.dart';

class CollaboratorsPage extends StatefulWidget {
  final Project project;

  CollaboratorsPage({required this.project});

  @override
  _CollaboratorsPageState createState() => _CollaboratorsPageState();
}

class _CollaboratorsPageState extends State<CollaboratorsPage> {
  bool _isConnected = true;  // Default to true, will be updated in initState

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    bool isConnected = await ConnectionChecker.checkConnection();
    setState(() {
      _isConnected = isConnected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final CollaboratorsController controller = Get.put(CollaboratorsController(projectId: widget.project.projectID));
    final currentUserID = MainController.getVar('currentUser');

    if (!_isConnected) {
      return NoInternetScr();
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar',
                border: OutlineInputBorder(),
              ),
              onChanged: controller.filterCollaborators,
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.filteredCollaborators.isEmpty) {
                return const Center(child: Text('No se encontraron colaboradores.'));
              }
              return ListView.builder(
                itemCount: controller.filteredCollaborators.length,
                itemBuilder: (context, index) {
                  final collaborator = controller.filteredCollaborators[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(collaborator.profileData?['profilePicUrl'] ?? 'https://via.placeholder.com/150'),
                    ),
                    title: Text(collaborator.name ?? ''),
                    subtitle: Text(collaborator.email),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        controller.removeCollaborator(collaborator.userID!);
                      },
                    ),
                  );
                },
              );
            }),
          ),
          if (widget.project.proprietaryID == currentUserID)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  showAddCollaboratorDialog(context, controller);
                },
                child: const Text('Agregar Colaborador'),
              ),
            ),
        ],
      ),
    );
  }

  void showAddCollaboratorDialog(BuildContext context, CollaboratorsController controller) {
    final TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Colaborador'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                AppLog.d('Botón de agregar colaborador presionado');
                String email = emailController.text.trim();
                User? user = await CollaboratorsController.getUserWithEmail(email);
                if (user != null) {
                  controller.addCollaborator(user);
                  Navigator.of(context).pop();
                } else {
                  AppLog.d('Usuario no encontrado');
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario no encontrado')));
                }
              },
              child: const Text('Añadir'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
}
