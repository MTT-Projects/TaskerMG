import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:taskermg/controllers/maincontroller.dart';

class ConnectionChecker {
  static Future<bool> checkConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile || 
        connectivityResult == ConnectivityResult.wifi) {
          MainController.setVar("isOffline", false);
      return true;
    } else {
      MainController.setVar("isOffline", true);
      return false;
    }
  }
}
