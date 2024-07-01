import 'package:date_picker_timeline/date_picker_timeline.dart';
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


class ProjectsPage extends StatefulWidget {
  ProjectsPage({Key? key}) : super(key: key);

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

//pagina para mostrar la lista de proyectos
class _ProjectsPageState extends State<ProjectsPage> {
  var screenTitle = "Proyectos";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: globalheader(context.theme.backgroundColor, screenTitle),
      backgroundColor: context.theme.backgroundColor,
      body: Column(
        children: [
          //_addTaskbar(),
         // _addDateBar(),
          const SizedBox(
            height: 10,
          ),
         // _showTasks(),
        ],
      ),
    );
  }
}

