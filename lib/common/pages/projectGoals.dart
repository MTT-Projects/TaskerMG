import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:taskermg/common/theme.dart';
import 'package:taskermg/controllers/project_controller.dart';
import 'package:taskermg/models/project.dart';

class ProjectGoalsPage extends StatefulWidget {
  final Project project;

  ProjectGoalsPage({required this.project});

  @override
  _ProjectGoalsPageState createState() => _ProjectGoalsPageState();
}

class _ProjectGoalsPageState extends State<ProjectGoalsPage> {
  final ProjectGoalController _goalController = Get.put(ProjectGoalController());
  final TextEditingController _goalDescriptionController = TextEditingController();
  List<ProjectGoal> _projectGoals = [];

  @override
  void initState() {
    super.initState();
    _loadProjectGoals();
  }

  Future<void> _loadProjectGoals() async {
    _projectGoals = await _goalController.getGoalsByProjectId(widget.project.projectID ?? widget.project.locId!);
    setState(() {});
  }

  void _addGoal() {
    if (_goalDescriptionController.text.isNotEmpty) {
      ProjectGoal newGoal = ProjectGoal(
        projectID: widget.project.projectID,
        goalDescription: _goalDescriptionController.text,
        isCompleted: 0,
        lastUpdate: DateTime.now(),
      );
      _goalController.addProjectGoal(newGoal);
      _goalDescriptionController.clear();
      _loadProjectGoals();
    } else {
      Get.snackbar('Error', 'La descripción del objetivo no puede estar vacía.');
    }
  }

  void _toggleGoalCompletion(ProjectGoal goal) {
    goal.isCompleted = goal.isCompleted == 1 ? 0 : 1;
    goal.lastUpdate = DateTime.now();
    _goalController.updateGoal(goal);
    _loadProjectGoals();
  }

  void _deleteGoal(ProjectGoal goal) {
    Get.defaultDialog(
      title: "Confirmar Eliminación",
      middleText: "¿Estás seguro de que deseas eliminar este objetivo?",
      textCancel: "Cancelar",
      textConfirm: "Eliminar",
      confirmTextColor: Colors.white,
      onConfirm: () {
        _goalController.deleteGoal(goal);
        _loadProjectGoals();
        Get.back();
      },
    );
  }

  double _calculateProgress() {
    if (_projectGoals.isEmpty) return 0.0;
    int completedGoals = _projectGoals.where((goal) => goal.isCompleted == 1).length;
    return completedGoals / _projectGoals.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            LinearPercentIndicator(
              animation: true,
              lineHeight: 20.0,
              animationDuration: 1200,
              percent: _calculateProgress(),
              center: Text(
                '${(_calculateProgress() * 100).toStringAsFixed(1)}%',
                style: TextStyle(color: AppColors.secTextColor),
              ),
              linearStrokeCap: LinearStrokeCap.roundAll,
              progressColor: AppColors.primaryColor,
              backgroundColor: AppColors.secBackgroundColor,
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _projectGoals.length,
                itemBuilder: (context, index) {
                  ProjectGoal goal = _projectGoals[index];
                  return ListTile(
                    title: Text(
                      goal.goalDescription ?? '',
                      style: TextStyle(
                        decoration: goal.isCompleted == 1
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            goal.isCompleted == 1 ? Icons.check_box : Icons.check_box_outline_blank,
                            color: AppColors.primaryColor,
                          ),
                          onPressed: () {
                            _toggleGoalCompletion(goal);
                          },
                        ),
                      ],
                    ),
                    onLongPress: () {
                      _deleteGoal(goal);
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _goalDescriptionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción del Objetivo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: AppColors.primaryColor),
                    onPressed: _addGoal,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
