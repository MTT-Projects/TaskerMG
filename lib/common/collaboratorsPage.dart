import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taskermg/controllers/collaboratorsController.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/models/project.dart';
import '../models/user.dart';

class CollaboratorsPage extends StatelessWidget {
  final Project project;

  CollaboratorsPage({required this.project});

  @override
  Widget build(BuildContext context) {
    final CollaboratorsController controller = Get.put(CollaboratorsController(projectId: project.projectID));
    final currentUserID = MainController.getVar('currentUser');

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
              onChanged: controller.filterCollaborators,
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.filteredCollaborators.isEmpty) {
                return Center(child: Text('No collaborators found.'));
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
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        controller.removeCollaborator(collaborator.userID!);
                      },
                    ),
                  );
                },
              );
            }),
          ),
          if (project.proprietaryID == currentUserID)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  showAddCollaboratorDialog(context, controller);
                },
                child: Text('Add Collaborator'),
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
          title: Text('Add Collaborator'),
          content: TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Email',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String email = emailController.text.trim();
                User? user = await getUserByEmail(email);
                if (user != null) {
                  controller.addCollaborator(user);
                  Navigator.of(context).pop();
                } else {
                  // Mostrar un mensaje de error si el usuario no se encuentra
                }
              },
              child: Text('Add'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<User?> getUserByEmail(String email) async {
    var result = await LocalDB.db.query('user', where: 'email = ?', whereArgs: [email]);
    if (result.isNotEmpty) {
      return User.fromJson(result.first);
    }
    return null;
  }
}
