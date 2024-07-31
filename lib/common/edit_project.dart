// ignore_for_file: library_private_types_in_public_api, prefer_const_constructors, deprecated_member_use, use_key_in_widget_constructors, prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taskermg/common/theme.dart';
import 'package:taskermg/controllers/project_controller.dart';
import 'package:taskermg/models/project.dart';
import 'package:intl/intl.dart';

class EditProjectScreen extends StatefulWidget {
  final Project project;

  EditProjectScreen({required this.project});

  @override
  _EditProjectScreenState createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final ProjectController _projectController = Get.find();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDeadline = DateTime.now();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.project.name ?? '';
    _descriptionController.text = widget.project.description ?? '';
    _selectedDeadline = widget.project.deadline ?? DateTime.now();
  }

  _pickDeadline() async {
    DateTime? pickedDate = await _selectDate(context, _selectedDeadline);
    if (pickedDate != null) {
      setState(() {
        _selectedDeadline = pickedDate;
      });
    }
  }

  Future<DateTime?> _selectDate(
      BuildContext context, DateTime selectedDate) async {
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
                            AppColors.secondaryColor,
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

  _saveProject() {
    if (_nameController.text.isNotEmpty) {
      Project updatedProject = Project(
        locId: widget.project.locId,
        projectID: widget.project.projectID,
        name: _nameController.text,
        description: _descriptionController.text,
        deadline: _selectedDeadline,
        proprietaryID: widget.project.proprietaryID,
        creationDate: widget.project.creationDate,
        lastUpdate: DateTime.now().toUtc(),
      );
      _projectController.updateProject(updatedProject);
      Get.back();
    } else {
      Get.snackbar(
        "Error",
        "El nombre del proyecto no puede estar vacío.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        icon: Icon(Icons.error, color: Colors.white),
      );
    }
  }

  _deleteProject() {
    _projectController.deleteProject(widget.project);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      
      body: Container(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Nombre",
                  labelStyle: TextStyle(color: AppColors.textColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.secondaryColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: "Descripción",
                  labelStyle: TextStyle(color: AppColors.textColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.secondaryColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Fecha límite: ${DateFormat('dd-MM-yyyy').format(_selectedDeadline)}",
                      style: TextStyle(fontSize: 16, color: AppColors.textColor),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_today, color: AppColors.secondaryColor),
                    onPressed: _pickDeadline,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveProject,
        child: Icon(Icons.save),
        backgroundColor: AppColors.secondaryColor,
      ),
    );
  }
}
