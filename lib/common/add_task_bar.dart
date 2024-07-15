// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:taskermg/common/theme.dart';
import 'package:taskermg/common/widgets/button.dart';
import 'package:taskermg/common/widgets/input_field.dart';
import 'package:taskermg/controllers/task_controller.dart';
import '../controllers/maincontroller.dart';
import '../models/task.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TaskController _taskController = Get.put(TaskController());
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDeadline = DateTime.now().toUtc();
  String _selectedPriority = 'Media';
  String _selectedStatus = 'Pendiente';

  final List<String> _priorityList = ['Baja', 'Media', 'Alta'];
  final List<String> _statusList = ['Pendiente', 'En Proceso', 'Completada'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: _appBar(context),
      body: Container(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Añadir Tarea",
                style: headingStyle,
              ),
              MyInputField(
                title: "Título",
                hint: "Ingresa el título",
                controller: _titleController,
              ),
              MyInputField(
                title: "Descripción",
                hint: "Ingresa la descripción",
                controller: _descriptionController,
              ),
              MyInputField(
                title: "Fecha de Entrega",
                hint: DateFormat.yMd().format(_selectedDeadline),
                widget: IconButton(
                    icon: const Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () async {
                      DateTime? pickedDate =
                          await _selectDate(context, _selectedDeadline);
                      if (pickedDate != null) {
                        setState(() {
                          _selectedDeadline = pickedDate;
                        });
                      }
                    }),
              ),
              MyInputField(
                title: "Prioridad",
                hint: _selectedPriority,
                widget: DropdownButton<String>(
                  value: _selectedPriority,
                  icon:
                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  iconSize: 32,
                  elevation: 4,
                  style: subTitleStyle,
                  underline: Container(height: 0),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPriority = newValue!;
                    });
                  },
                  items: _priorityList
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value,
                          style: const TextStyle(color: Colors.grey)),
                    );
                  }).toList(),
                ),
              ),
              MyInputField(
                title: "Estado",
                hint: _selectedStatus,
                widget: DropdownButton<String>(
                  value: _selectedStatus,
                  icon:
                      const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  iconSize: 32,
                  elevation: 4,
                  style: subTitleStyle,
                  underline: Container(height: 0),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedStatus = newValue!;
                    });
                  },
                  items:
                      _statusList.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value,
                          style: const TextStyle(color: Colors.grey)),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  MyButton(label: "Crear Tarea", onTab: () async => await _validateData())
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _validateData() async {
    if (_titleController.text.isNotEmpty) {
      await _addTaskToDb();
      Get.back();
    } else {
      Get.snackbar(
        "Requerido",
        "¡El título es obligatorio!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: pinkClr,
        icon: const Icon(Icons.warning_amber_rounded),
      );
    }
  }

  _addTaskToDb() async {
    int value = await _taskController.addTask(
      task: Task(
        projectID: MainController.getVar('currentProject'),
        createdUserID: MainController.getVar('userID'),
        title: _titleController.text,
        description: _descriptionController.text,
        deadline: _selectedDeadline,
        priority: _selectedPriority,
        status: _selectedStatus,
        lastUpdate: DateTime.now().toUtc(),
        creationDate: DateTime.now().toUtc(),
      ),
    );
    print("Nuevo ID: $value");
  }

  _appBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.backgroundColor,
      leading: GestureDetector(
        onTap: () {
          Get.back();
        },
        child: Icon(
          Icons.arrow_back_ios,
          size: 20,
          color: AppColors.textColor,
        ),
      ),
      actions: const [
        CircleAvatar(
          backgroundImage: AssetImage(
            "Assets/images/profile.png",
          ),
        ),
        SizedBox(width: 20),
      ],
    );
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
}
