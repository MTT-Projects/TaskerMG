import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:taskermg/common/theme.dart';
import '../../models/task.dart';
import '../../db/db_local.dart';

class TaskTile extends StatelessWidget {
  final Task? task;

  TaskTile(this.task);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: getTaskCommentsCount(task?.taskID ?? 0),
      builder: (context, snapshot) {
        int commentCount = snapshot.data ?? 0;
        return Container(
          color: AppColors.backgroundColor2,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  AppColors.secondaryColor,
                  AppColors.primaryColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            task?.title ?? "",
                            style: GoogleFonts.lato(
                              textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                          Row(children: [
                            Icon(
                              Icons.comment_rounded,
                              color: Colors.grey[200],
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$commentCount",
                              style: GoogleFonts.lato(
                                textStyle: TextStyle(
                                    fontSize: 13, color: Colors.grey[100]),
                              ),
                            ),
                          ]),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        task?.description ?? "",
                        style: GoogleFonts.lato(
                          textStyle:
                              TextStyle(fontSize: 15, color: Colors.grey[100]),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.grey[200],
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('yyyy-MM-dd')
                              .format(task?.deadline ?? DateTime.now()),
                          style: GoogleFonts.lato(
                            textStyle:
                                TextStyle(fontSize: 13, color: Colors.grey[100]),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              color: Colors.grey[200],
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getDeadlineText(task?.deadline),
                              style: GoogleFonts.lato(
                                textStyle: TextStyle(
                                    fontSize: 13, color: Colors.grey[100]),
                              ),
                            ),
                          ],
                        ),
                      ]),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  height: 100,
                  width: 8,
                  color: _getPriorityColor(task?.priority ?? "Media"),
                ),
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    task?.status ?? "",
                    style: GoogleFonts.lato(
                      textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<int> getTaskCommentsCount(int taskID) async {
    var response = await LocalDB.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM taskComment
      WHERE taskID = ?
    ''',
      [taskID],
    );

    return response[0]["count"];
  }

  String _getDeadlineText(DateTime? deadline) {
    if (deadline == null) {
      return "Sin fecha límite";
    }

    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;

    if (difference > 0) {
      return "$difference días restantes";
    } else if (difference == 0) {
      return "Vence hoy";
    } else {
      return "Retrasada por ${difference.abs()} días";
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Alta':
        return Color.fromRGBO(255, 0, 0, 1);
      case 'Media':
        return Color.fromARGB(255, 255, 238, 0);
      case 'Baja':
        return Color.fromRGBO(64, 202, 0, 1);
      default:
        return Colors.grey;
    }
  }
}
