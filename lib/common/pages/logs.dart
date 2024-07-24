import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:taskermg/controllers/logActivityController.dart';
import 'package:taskermg/models/activity_log.dart';
import 'package:taskermg/common/theme.dart';
import 'package:taskermg/models/project.dart';

class LogActivityPage extends StatefulWidget {
  final Project project;

  LogActivityPage({required this.project});

  @override
  _LogActivityPageState createState() => _LogActivityPageState();
}

class _LogActivityPageState extends State<LogActivityPage> {
  final LogActivityController _controller = Get.put(LogActivityController());

  @override
  void initState() {
    super.initState();
    _controller.fetchActivityLogs(widget.project.projectID!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (_controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (_controller.activityLogs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('No hay registros de actividad.'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: _controller.activityLogs.length,
          itemBuilder: (context, index) {
            ActivityLog log = _controller.activityLogs[index];
            var userData = _controller.getUserData(log.userID!);
            var taskName = _controller.getTaskName(log.activityDetails?['taskID']);
            return _buildLogTile(log, userData, taskName);
          },
        );
      }),
    );
  }

  Widget _buildLogTile(ActivityLog log, Map<String, dynamic>? userData, String? taskName) {
    LinearGradient getStatusGradient(String? state) {
      switch (state) {
        case 'Pendiente':
          return LinearGradient(
            colors: [Colors.grey.shade300, Colors.grey.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        case 'En Proceso':
          return LinearGradient(
            colors: [Colors.orange.shade300, Colors.orange.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        case 'Completada':
          return LinearGradient(
            colors: [Colors.green.shade300, Colors.green.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        default:
          return LinearGradient(
            colors: [Colors.white, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: getStatusGradient(log.activityDetails?['newState']),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: CircleAvatar(
              backgroundImage: userData != null && userData['profilePicUrl'] != null
                  ? NetworkImage(userData['profilePicUrl'])
                  : AssetImage("Assets/images/profile.png") as ImageProvider,
              radius: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${userData?['name'] ?? 'Usuario'} ',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      TextSpan(
                        text: 'ha marcado la tarea ',
                        style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
                      ),
                      TextSpan(
                        text: '"${taskName ?? 'desconocida'}" ',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      TextSpan(
                        text: 'como ',
                        style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
                      ),
                      TextSpan(
                        text: '${log.activityDetails?['newState']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  DateFormat('dd-MM-yyyy HH:mm').format(log.timestamp!),
                  style: const TextStyle(fontSize: 12, color: Color.fromRGBO(43, 43, 43, 1))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
