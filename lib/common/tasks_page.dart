// ignore_for_file: prefer_const_constructors

import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:lottie/lottie.dart';
import 'package:taskermg/common/add_task_bar.dart';
import 'package:taskermg/common/pages/profile.dart';
import 'package:taskermg/common/theme.dart';
import 'package:taskermg/common/widgets/button.dart';
import 'package:taskermg/common/widgets/task_tile.dart';
import 'package:taskermg/services/notification_services.dart';
import 'package:taskermg/services/theme_services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';

import '../controllers/task_controller.dart';
import '../models/task.dart';
import '../views/globalheader.dart';
import '../utils/AppLog.dart';

class TasksPage extends StatefulWidget {
  TasksPage({Key? key}) : super(key: key);

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  var screenTitle = "Pendientes";
  DateTime _selectedDate = DateTime.now();
  final _taskController = Get.put(TaskController());

  var notifyHelper;

  @override
  void initState() {
    super.initState();
    notifyHelper = NotifyHelper();
    notifyHelper.initializeNotification();
    notifyHelper.requestIOSPermissions();
  }

  int _filterIndex = -1;
  int taskFilter = 0;

  @override
  Widget build(BuildContext context) {
    var addButton = FloatingActionButton(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.values[1],
          gradient: LinearGradient(
            colors: [AppColors.secondaryColor, AppColors.primaryColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: AppColors.backgroundColor, width: 3),
        ),
        child: Icon(
          Icons.add,
          size: 40,
        ),
      ),
      onPressed: () {
        Get.to(() => AddTaskPage());
      },
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      //add float buton
      floatingActionButton: taskFilter == 0 ? addButton : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      //bottom appbar
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        color: AppColors.secBackgroundColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            //Button "Todas las tareas"
            IconButton(
              onPressed: () {
                setState(() {
                  taskFilter = 0;
                  screenTitle = "Todas las tareas";
                  _taskController.getTasks();
                });
              },
              icon: Icon(Icons.all_inbox,
                  color: taskFilter == 0
                      ? AppColors.secondaryColor
                      : AppColors.backgroundColor),
            ),
            //Espacio en blancl
            SizedBox(
              width: 50,
            ),
            //Button "Tareas Asignadas"
            IconButton(
              onPressed: () {
                setState(() {
                  taskFilter = 1;
                  screenTitle = "Tareas Asignadas";
                  _taskController.getAssignedTasks();
                });
              },
              icon: Icon(Icons.timelapse,
                  color: taskFilter == 1
                      ? AppColors.secondaryColor
                      : AppColors.backgroundColor),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _addTaskbar(),
          const SizedBox(
            height: 10,
          ),
          _showTasks(),
        ],
      ),
    );
  }

  _showTasks() {
    AppLog.d("TaskList: ${_taskController.taskList}");
    return Expanded(
      child: Obx(() {
        List<Task> filteredTasks = [];
        if (_filterIndex >= 0) {
          filteredTasks = _taskController.taskList.where((task) {
            if (_filterIndex == 0) return task.status == 'Pendiente';
            if (_filterIndex == 1) return task.status == 'En Proceso';
            if (_filterIndex == 2) return task.status == 'Completada';
            return true;
          }).toList();
        } else {
          filteredTasks = _taskController.taskList;
        }

        if (filteredTasks.isEmpty) {
          return Center(
            child: Lottie.asset('Assets/lotties/done3.json',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high),
          );
        }

        return ListView.builder(
          itemCount: filteredTasks.length,
          itemBuilder: (_, index) {
            Task task = filteredTasks[index];
            AppLog.i("Task n'{$index}':${task.toJson()}");

            return AnimationConfiguration.staggeredList(
              position: index,
              child: SlideAnimation(
                child: FadeInAnimation(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _showBottomSheet(context, task);
                          AppLog.d("Selected Task: ${task.toJson()}");
                        },
                        child: TaskTile(task),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  String _getEmptyMessage() {
    if (_filterIndex == 0) {
      return 'Sin tareas pendientes, prueba agregar una';
    } else if (_filterIndex == 1) {
      return 'Sin tareas en proceso, prueba agregar una';
    } else if (_filterIndex == 2) {
      return 'Sin tareas completadas, prueba agregar una';
    } else {
      return 'No hay tareas disponibles';
    }
  }

  _showBottomSheet(BuildContext context, Task task) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.only(top: 4),
        height: task.status == 'Completada'
            ? MediaQuery.of(context).size.height * 0.24
            : MediaQuery.of(context).size.height * 0.32,
        color: Get.isDarkMode ? darkGreyClr : Colors.white,
        child: Column(
          children: [
            Container(
              height: 6,
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Get.isDarkMode ? Colors.grey[600] : Colors.grey[300],
              ),
            ),
            const Spacer(),
            task.status == 'Completada'
                ? Container()
                : _bottomSheetButton(
                    label: "Marcar como Completada",
                    onTap: () {
                      _taskController.markTaskCompleted(task);
                      Get.back();
                    },
                    clr: AppColors.primaryColor,
                    context: context,
                  ),
            _bottomSheetButton(
              label: "Eliminar Tarea",
              onTap: () {
                TaskController.deleteTask(task);
                Get.back();
              },
              clr: Colors.red[300]!,
              context: context,
            ),
            const SizedBox(
              height: 20,
            ),
            _bottomSheetButton(
              label: "Cerrar",
              onTap: () {
                Get.back();
              },
              clr: Colors.white,
              isClosed: true,
              context: context,
            )
          ],
        ),
      ),
    );
  }

  _bottomSheetButton({
    required String label,
    required Function()? onTap,
    required Color clr,
    bool isClosed = false,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        height: 55,
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          border: Border.all(
            width: 2,
            color: isClosed == true
                ? Get.isDarkMode
                    ? Colors.grey[600]!
                    : Colors.grey[300]!
                : clr,
          ),
          borderRadius: BorderRadius.circular(20),
          color: isClosed == true ? Colors.transparent : clr,
        ),
        child: Center(
          child: Text(
            label,
            style: isClosed
                ? titleStyle
                : titleStyle.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }

  _addTaskbar() {
    var allColor = Get.isDarkMode ? Colors.white : Colors.black;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Title"),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            height: 35, // Height for the horizontal ListView
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              children: [
                IconButton(
                  //background color
                  color: AppColors.secBackgroundColor,
                  padding: const EdgeInsets.all(0),
                  onPressed: () {
                    setState(() {
                      _filterIndex = -1;
                      screenTitle = "Todas las tareas";
                    });
                  },
                  icon: Icon(
                    Icons.filter_list_off,
                    color: _filterIndex == -1
                        ? AppColors.secondaryColor
                        : allColor,
                  ),
                ),
                _filterButton(
                  index: 0,
                  icon: Icons.timelapse,
                  label: 'Pendiente',
                ),
                SizedBox(
                  width: 5,
                ),
                _filterButton(
                  index: 1,
                  icon: Icons.work,
                  label: 'En Proceso',
                ),
                SizedBox(
                  width: 5,
                ),
                _filterButton(
                  index: 2,
                  icon: Icons.check_circle,
                  label: 'Completada',
                ),
              ],
            ),
          )
        ]);
  }

  _filterButton(
      {required int index, required IconData icon, required String label}) {
    bool isSelected = _filterIndex == index;
    return TextButton.icon(
      style: TextButton.styleFrom(
        textStyle: TextStyle(color: Colors.black, fontSize: 10),
        backgroundColor: isSelected
            ? AppColors.secondaryColor
            : AppColors.secBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
      ),
      onPressed: () {
        setState(() {
          _filterIndex = index;
          screenTitle = label;
        });
      },
      icon: Icon(
        icon,
        color: isSelected ? AppColors.textColor : AppColors.primaryColor,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.textColor : AppColors.primaryColor,
        ),
      ),
    );
  }
}
