import 'package:flutter/material.dart';
import 'package:taskermg/models/activity_log.dart';

import '../db/db_local.dart';

class ActivityLogController extends ChangeNotifier {
  
  static Future<void> updateAcLog(ActivityLog activityLog) async {
    await LocalDB.update(
      'activityLog',
      activityLog.toJson(),
      where: 'locId = ?',
      whereArgs: [activityLog.locId],
    );
    
  }
}