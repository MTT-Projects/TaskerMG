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
            return FutureBuilder<Map<String, dynamic>?>(
              future: _controller.getUserDataById(log.userID!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var userData = snapshot.data;
                return _buildLogTile(log, userData);
              },
            );
          },
        );
      }),
    );
  }

  Widget _buildLogTile(ActivityLog log, Map<String, dynamic>? userData) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
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
          CircleAvatar(
            backgroundImage: userData != null && userData['profilePicUrl'] != null
                ? NetworkImage(userData['profilePicUrl'])
                : AssetImage("Assets/images/profile.png") as ImageProvider,
            radius: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${userData?['name'] ?? 'Usuario'} ha marcado la tarea como ${log.activityDetails?['newState']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  DateFormat('dd-MM-yyyy HH:mm').format(log.timestamp!),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
