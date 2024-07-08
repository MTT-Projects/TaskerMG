// ignore_for_file: prefer_const_constructors

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taskermg/common/theme.dart';

import '../controllers/maincontroller.dart';
import '../controllers/project_controller.dart';
import '../models/project.dart';

class AddProjectPage extends StatefulWidget {
  const AddProjectPage({super.key});

  @override
  State<AddProjectPage> createState() => _AddProjectPageState();
}

class _AddProjectPageState extends State<AddProjectPage> {
  final MainController MC = Get.put(MainController());
  final ProjectController _projectController = Get.put(ProjectController());
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDeadline = DateTime.now();

  @override
  Widget build(BuildContext context) {
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
                    DateTime? pickedDate = await _selectDate(context, _selectedDeadline);
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProject,
              child: Text('Guardar Proyecto'),
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _selectDate(BuildContext context, DateTime selectedDate) async {
    DateTime? pickedDate;
    return showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: Get.isDarkMode ? _darkDatePickerTheme() : _lightDatePickerTheme(),
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

  ThemeData _lightDatePickerTheme() {
    return ThemeData.light().copyWith(
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryColor,
        onPrimary: Colors.white,
        surface: AppColors.cardColor,
        onSurface: Colors.black,
      ),
      dialogBackgroundColor: AppColors.backgroundColor,
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(primary: AppColors.primaryColor),
      ),
    );
  }

  ThemeData _darkDatePickerTheme() {
    return ThemeData.dark().copyWith(
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryColor,
        onPrimary: Colors.white,
        surface: AppColors.cardColor,
        onSurface: Colors.white,
      ),
      dialogBackgroundColor: AppColors.backgroundColor,
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(primary: AppColors.primaryColor),
      ),
    );
  }

  _saveProject() {
    final name = _nameController.text;
    final description = _descriptionController.text;

    if (name.isEmpty || description.isEmpty) {
      Get.snackbar('Error', 'Todos los campos son obligatorios');
      return;
    }

    final project = Project(
      name: name,
      description: description,
      deadline: _selectedDeadline,
      proprietaryID: MC.getVar('currentUser'), // Cambia esto por el ID del usuario actual
      creationDate: DateTime.now(),
      lastUpdate: DateTime.now(),
    );

    _projectController.addProject(project);
    Get.back();
  }
}

mixin MasterController {
}
