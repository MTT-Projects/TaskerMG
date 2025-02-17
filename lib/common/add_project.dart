import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taskermg/common/projects_page.dart';
import 'package:taskermg/common/theme.dart';
import 'package:taskermg/controllers/sync_controller.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/controllers/project_controller.dart';
import 'package:taskermg/models/project.dart';

class AddProjectPage extends StatefulWidget {
  const AddProjectPage({super.key});

  @override
  State<AddProjectPage> createState() => _AddProjectPageState();
}

class _AddProjectPageState extends State<AddProjectPage> {
  final ProjectController _projectController = Get.put(ProjectController());
  final ProjectGoalController _goalController = Get.put(ProjectGoalController());
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _goalControllerText = TextEditingController();
  final SyncController syncController = Get.put(SyncController());
  DateTime _selectedDeadline = DateTime.now().toUtc();
  List<String> goals = [];

  @override
  Widget build(BuildContext context) {
    syncController.switchCanSync();
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text('Añadir Proyecto', style: headingStyleInv),
        backgroundColor: AppColors.secBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(50), bottomRight: Radius.circular(50)),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nombre del Proyecto'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Descripción'),
              ),
              SizedBox(height: 20),
              Text('Fecha de Entrega'),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "${_selectedDeadline.toLocal()}".split(' ')[0],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      DateTime? pickedDate =
                          await _selectDate(context, _selectedDeadline);
                      if (pickedDate != null) {
                        setState(() {
                          _selectedDeadline = pickedDate;
                        });
                        print('Fecha seleccionada: $pickedDate');
                      }
                    },
                  ),
                ],
              ),
              // SizedBox(height: 20),
              // TextField(
              //   controller: _goalControllerText,
              //   decoration: InputDecoration(
              //     labelText: 'Objetivo del Proyecto',
              //     suffixIcon: IconButton(
              //       icon: Icon(Icons.add),
              //       onPressed: () {
              //         setState(() {
              //           goals.add(_goalControllerText.text);
              //           _goalControllerText.clear();
              //         });
              //       },
              //     ),
              //   ),
              // ),
              // SizedBox(height: 20),
              // Text(
              //   'Objetivos',
              //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              // ),
              // ListView.builder(
              //   shrinkWrap: true,
              //   itemCount: goals.length,
              //   itemBuilder: (context, index) {
              //     return ListTile(
              //       title: Text(goals[index]),
              //       trailing: IconButton(
              //         icon: Icon(Icons.delete),
              //         onPressed: () {
              //           setState(() {
              //             goals.removeAt(index);
              //           });
              //         },
              //       ),
              //     );
              //   },
              // ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveProject,
        child: Icon(Icons.save),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  Future<DateTime?> _selectDate(BuildContext context, DateTime selectedDate) async {
    DateTime? pickedDate;
    return showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: Get.isDarkMode ? darkDatePickerTheme : lightDatePickerTheme,
          child: Builder(
            builder: (context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor,
                            AppColors.secondaryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12.0),
                        ),
                      ),
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'Seleccionar Fecha',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 400,
                      child: Builder(
                        builder: (context) {
                          return CalendarDatePicker(
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                            onDateChanged: (DateTime value) {
                              pickedDate = value;
                            },
                          );
                        },
                      ),
                    ),
                    ButtonBar(
                      children: <Widget>[
                        TextButton(
                          child: Text('CANCELAR'),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        TextButton(
                          child: Text('SELECCIONAR'),
                          onPressed: () {
                            Navigator.pop(context, pickedDate);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  _saveProject() async {
    final name = _nameController.text;
    final description = _descriptionController.text;

    if (name.isEmpty) {
      Get.snackbar('Error', 'El nombre del proyecto no puede estar vacío');
      return;
    } else {
      final project = Project(
        name: name,
        description: description,
        deadline: _selectedDeadline,
        proprietaryID: MainController.getVar('currentUser'),
        creationDate: DateTime.now().toUtc(),
        lastUpdate: DateTime.now().toUtc(),
      );

      int projectId = await _projectController.addProject(project);
      
      // for (String goal in goals) {
      //   await _goalController.addProjectGoal(ProjectGoal(
      //     projectID: projectId,
      //     goalDescription: goal,
      //     isCompleted: 0,
      //     lastUpdate: DateTime.now().toUtc(),
      //   ));
      // }
      
      await ProjectPage.projectController.getProjects();
      syncController.switchCanSync();
      Get.back();
    }
  }
}

mixin MasterController {}
