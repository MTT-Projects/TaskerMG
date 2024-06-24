class MainController {
  // Singleton
  static final MainController _instance = MainController._internal();

  factory MainController() {
    return _instance;
  }

  MainController._internal();

  // Variables globales
  final Map<String, dynamic> _dynamicVariables = {};

  dynamic getVar(String key) {
    return _dynamicVariables[key];
  }

  void setVar(String key, dynamic value) {
    _dynamicVariables[key] = value;
  }
}
