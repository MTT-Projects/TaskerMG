import '../utils/AppLog.dart';

class MainController {
  // Singleton
  static final MainController _instance = MainController._internal();

  factory MainController() {
    return _instance;
  }

  MainController._internal();

  // Variables globales
  static final Map<String, dynamic> _dynamicVariables = {};

  static dynamic getVar(String key) {
    AppLog.d("Getting $key, value: ${_dynamicVariables[key]}" );
    return _dynamicVariables[key];
  }

   static setVar(String key, dynamic value) {
    AppLog.d("Setting $key to $value");
    _dynamicVariables[key] = value;
   }
}
