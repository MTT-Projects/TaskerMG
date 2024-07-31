import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taskermg/common/theme.dart';
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
  bool _isConnected = true; // Default to true, will be updated in initState

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  bool imOwner() {
    return MainController.getVar("currentUser") == widget.project.proprietaryID;
  }

  Future<void> _checkConnection() async {
    bool isConnected = await ConnectionChecker.checkConnection();
    setState(() {
      _isConnected = isConnected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final CollaboratorsController controller =
        Get.put(CollaboratorsController(projectId: widget.project.projectID));
    final currentUserID = MainController.getVar('currentUser');

    if (!_isConnected) {
      return NoInternetScr();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          imOwner()
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Buscar',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: controller.filterCollaborators,
                  ),
                )
              : const SizedBox(
                  height: 25,
                ),
          Expanded(
            child: Obx(() {
              if (controller.filteredCollaborators.isEmpty) {
                return const Center(
                    child: Text('No se encontraron colaboradores.'));
              }
              return ListView.builder(
                itemCount: controller.filteredCollaborators.length,
                itemBuilder: (context, index) {
                  final collaborator = controller.filteredCollaborators[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                          collaborator.profileData?['profilePicUrl'] ??
                              'https://via.placeholder.com/150'),
                    ),
                    title: Text(collaborator.name ?? ''),
                    subtitle: Text(collaborator.email),
                    trailing: collaborator.userID != currentUserID
                        ? imOwner()
                            ? IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  controller
                                      .removeCollaborator(collaborator.userID!);
                                },
                              )
                            : null
                        : null,
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
                  controller.searchResults.clear();
                  showAddCollaboratorDialog(context, controller);
                },
                child: const Text('Agregar Colaborador'),
              ),
            ),
        ],
      ),
    );
  }

  void showAddCollaboratorDialog(
      BuildContext context, CollaboratorsController controller) {
    final TextEditingController searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Colaborador'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: 'Buscar usuario por nombre o correo',
                ),
                onChanged: (value) {
                  controller.searchUser(value);
                },
              ),
              const SizedBox(height: 20),
              Obx(() {
                if (controller.searchResults.isEmpty) {
                  return const Text('No se encontraron usuarios.');
                }
                return SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: controller.searchResults.length,
                    itemBuilder: (context, index) {
                      final user = controller.searchResults[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(
                              user.profileData?['profilePicUrl'] ??
                                  'https://via.placeholder.com/150'),
                        ),
                        title: Text(user.name ?? ''),
                        subtitle: Text(user.email),
                        onTap: () async {                          
                          await controller.addCollaborator(user);
                          controller.searchResults.clear();
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                );
              }),
            ],
          ),
          actions: [
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
