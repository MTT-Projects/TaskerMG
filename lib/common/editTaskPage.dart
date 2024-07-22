// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, unused_local_variable

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:taskermg/common/theme.dart';
import 'package:taskermg/controllers/task_controller.dart';
import 'package:taskermg/models/task.dart';

class EditTaskPage extends StatefulWidget {
  final Task task;

  const EditTaskPage({super.key, required this.task});

  @override
  _EditTaskPageState createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  final _taskController = Get.put(TaskController());
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime _selectedDate = DateTime.now();
  String _selectedPriority = 'Baja';
  String _selectedStatus = 'Pendiente';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController =
        TextEditingController(text: widget.task.description);
    _selectedDate = widget.task.deadline ?? DateTime.now();
    _selectedPriority = widget.task.priority ?? 'Baja';
    _selectedStatus = widget.task.status ?? 'Pendiente';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Tarea'),
         backgroundColor: AppColors.secBackgroundColor,
      ),
      backgroundColor: AppColors.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese un título';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text(
                    'Fecha de Vencimiento: ${DateFormat.yMd().format(_selectedDate)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: InputDecoration(
                  labelText: 'Prioridad',
                  border: OutlineInputBorder(),
                ),
                items: ['Baja', 'Media', 'Alta'].map((String priority) {
                  return DropdownMenuItem<String>(
                    value: priority,
                    child: Text(priority),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedPriority = newValue!;
                  });
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: ['Pendiente', 'En Proceso', 'Completada']
                    .map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedStatus = newValue!;
                  });
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  var saveRes = await _saveTask();
                  //pop
                  if (saveRes) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Guardar Cambios',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<bool> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      Task updatedTask = Task(
        locId: widget.task.locId,
        createdUserID: widget.task.createdUserID,
        taskID: widget.task.taskID,
        projectID: widget.task.projectID,
        title: _titleController.text,
        description: _descriptionController.text,
        deadline: _selectedDate,
        priority: _selectedPriority,
        status: _selectedStatus,
        creationDate: widget.task.creationDate,
        lastUpdate: DateTime.now(),
      );

      await _taskController.updateTaskDetails(updatedTask);

      SnackBar snackBar = SnackBar(
        content: Text('Tarea actualizada correctamente',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
      );
      return true;
    } else {
      SnackBar snackBar = SnackBar(
        content: Text('Error al actualizar la tarea',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.errorColor,
      );
      return false;
    }
  }
}
