import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taskermg/common/widgets/popUpDialog.dart';
import 'package:taskermg/controllers/collaboratorsController.dart';
import 'package:taskermg/controllers/conecctionChecker.dart';
import 'package:taskermg/controllers/task_controller.dart';
import 'package:taskermg/models/task.dart';
import 'package:taskermg/models/user.dart';
import 'package:taskermg/common/theme.dart';
import 'package:taskermg/common/widgets/noInternet.dart';

class AssignTaskPage extends StatefulWidget {
  final Task task;

  AssignTaskPage({required this.task});

  @override
  _AssignTaskPageState createState() => _AssignTaskPageState();
}

class _AssignTaskPageState extends State<AssignTaskPage> {
  final TaskController _taskController = Get.put(TaskController());
  final CollaboratorsController _collaboratorsController = Get.put(CollaboratorsController());
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _taskController.getAssignedUsers(widget.task.taskID!);
  }

  Future<void> _checkConnection() async {
    bool isConnected = await ConnectionChecker.checkConnection();
    setState(() {
      _isConnected = isConnected;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected) {
      return NoInternetScr();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Asignar Tarea'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (_taskController.assignedUsers.isEmpty) {
                return Center(
                  child: Text('No hay usuarios asignados a esta tarea.'),
                );
              }
              return ListView.builder(
                itemCount: _taskController.assignedUsers.length,
                itemBuilder: (context, index) {
                  User user = _taskController.assignedUsers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(user.profileData!["profilePicUrl"] ?? 'https://via.placeholder.com/150'),
                    ),
                    title: Text(user.name ?? ''),
                    subtitle: Text(user.email),
                    trailing: IconButton(
                      icon: Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        _taskController.unassignUser(widget.task.taskID!, user.userID!);
                      },
                    ),
                  );
                },
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                _showAssignUserDialog(context);
              },
              child: Text('Agregar Usuario'),
              style: ElevatedButton.styleFrom(
                primary: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignUserDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return PopUpDialog(
          title: 'Asignar Usuario',
          text: 'Ingresa el correo del usuario a asignar:',
          icon: Icons.person_add,
          content: TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              border: OutlineInputBorder(),
            ),
          ),
          buttons: PopUpButtons.yesNo(context, () async {
            String email = emailController.text.trim();
            User? user = await CollaboratorsController.getUserWithEmail(email);
            if (user != null) {
              _taskController.assignUser(widget.task.taskID!, user.userID!);
              Navigator.of(context).pop();
            } else {
              // Mostrar un mensaje de error si el usuario no se encuentra
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario no encontrado')));
            }
          }),
        );
      },
    );
  }
}
