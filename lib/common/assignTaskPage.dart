import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  late CollaboratorsController _collaboratorsController;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _taskController.getAssignedUsers(widget.task.taskID!);
    _collaboratorsController = Get.put(CollaboratorsController(projectId: widget.task.projectID!));
  }

  //get assigned users
  void getAssignedUsers() async {
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
      backgroundColor: AppColors.backgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30.0),
            bottomRight: Radius.circular(30.0),
          ),
          child: AppBar(
            title: Text('Asignar Tarea', style: TextStyle(color: AppColors.secTextColor)),
            backgroundColor: AppColors.secBackgroundColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.secTextColor),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      body:  Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar',
                border: OutlineInputBorder(),
              ),
              onChanged: _collaboratorsController.filterCollaborators,
            ),
          ),
          Expanded(
            child: Obx(() {
              if (_collaboratorsController.filteredCollaborators.isEmpty) {
                return const Center(child: Text('No se encontraron colaboradores.'));
              }
              return ListView.builder(
                itemCount: _collaboratorsController.filteredCollaborators.length,
                itemBuilder: (context, index) {
                  User user = _collaboratorsController.filteredCollaborators[index];
                  bool isAssigned = _taskController.assignedUsers.any((u) => u.userID == user.userID);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(user.profileData?["profilePicUrl"] ?? 'https://via.placeholder.com/150'),
                    ),
                    title: Text(user.name ?? ''),
                    subtitle: Text(user.email),
                    trailing: Obx(() {
                      bool isCurrentlyAssigned = _taskController.assignedUsers.any((u) => u.userID == user.userID);
                      return IconButton(
                        icon: Icon(isCurrentlyAssigned ? Icons.remove_circle : Icons.add_circle, color: isCurrentlyAssigned ? Colors.red : Colors.green),
                        onPressed: () {
                          if (isCurrentlyAssigned) {
                            _taskController.unassignUser(widget.task.taskID!, user.userID!);
                            getAssignedUsers();
                          } else {
                            _taskController.assignUser(widget.task.taskID!, user.userID!);
                            getAssignedUsers();
                          }
                        },
                      );
                    }),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
