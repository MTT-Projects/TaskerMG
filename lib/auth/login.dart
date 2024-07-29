// ignore_for_file: use_build_context_synchronously

import 'package:taskermg/common/dashboard.dart';
import 'package:taskermg/common/profileEditPage.dart';
import 'package:taskermg/common/sync_screen.dart';
import 'package:taskermg/common/validationScreen.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/controllers/profileDataController.dart';
import 'package:taskermg/controllers/user_controller.dart';
import 'package:taskermg/controllers/collaboratorscontroller.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:taskermg/services/AuthService.dart';
import 'signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final username = TextEditingController();
  final password = TextEditingController();

  // Variable booleana para mostrar y ocultar la contraseña
  bool isVisible = false;
  bool? isLoginTrue;

  final storage = const FlutterSecureStorage();

  // Ahora deberíamos llamar a esta función en el botón de inicio de sesión
  Future<void> login(String username, String password) async {
    var response = await AuthService.login(username, password);
    if (response != null) {
      if (response['validated'] != 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              var validationScreen = ValidationScreen(userId: response['userID'],  email: response['email']);
              return validationScreen;
            },
          ),
        );
      } else {
        await storage.write(key: 'isLoggedIn', value: "true");
        await storage.write(key: 'username', value: username);
        await storage.write(key: 'password', value: password);

        //check if has profileData
        var profileData = await ProfileDataController.getProfileDataByUserID(
            MainController.getVar('currentUser'));
        if (profileData != null) {
          await storage.write(key: 'profileData', value: profileData.toString());
          if (!mounted) return;
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => SyncScreen()));
        } else {
          Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => ProfileEditPage()));
          setState(() {
            isLoginTrue = true;
          });
        }
      }
    } else {
      setState(() {
        isLoginTrue = false;
      });
    }

    // Si el inicio de sesión es correcto, redirige a la página principal
  }

  // Tenemos que crear una clave global para nuestro formulario
  final formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            // Ponemos todos nuestros campos de texto en un formulario para ser controlados y no permitir que estén vacíos
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  // Campo de nombre de usuario

                  // Antes de mostrar la imagen, después de copiar la imagen, necesitamos definir la ubicación en pubspec.yaml
                  Container(
                    margin: const EdgeInsets.all(30.0),
                    padding: const EdgeInsets.all(10.0),
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Colors.transparent,
                      border: Border.all(color: Colors.deepPurple, width: 10),
                    ),
                    child: Lottie.asset('Assets/lotties/login2.json',
                        width: 200, height: 200),
                  ),

                  const SizedBox(height: 15),
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.deepPurple.withOpacity(.2)),
                    child: TextFormField(
                      controller: username,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "El nombre de usuario es obligatorio";
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        icon: Icon(Icons.person),
                        border: InputBorder.none,
                        hintText: "Nombre de usuario",
                      ),
                    ),
                  ),

                  // Campo de contraseña
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.deepPurple.withOpacity(.2)),
                    child: TextFormField(
                      controller: password,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "La contraseña es obligatoria";
                        }
                        return null;
                      },
                      obscureText: !isVisible,
                      decoration: InputDecoration(
                          icon: const Icon(Icons.lock),
                          border: InputBorder.none,
                          hintText: "Contraseña",
                          suffixIcon: IconButton(
                              onPressed: () {
                                // Aquí crearemos un clic para mostrar y ocultar la contraseña, un botón de alternancia
                                setState(() {
                                  // botón de alternancia
                                  isVisible = !isVisible;
                                });
                              },
                              icon: Icon(isVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off))),
                    ),
                  ),

                  const SizedBox(height: 10),
                  // Botón de inicio de sesión
                  Container(
                    height: 55,
                    width: MediaQuery.of(context).size.width * .9,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.deepPurple),
                    child: TextButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            // El método de inicio de sesión estará aquí
                            login(username.text, password.text);

                            // Ahora tenemos una respuesta de nuestro método sqlite
                            // Vamos a crear un usuario
                          }
                        },
                        child: const Text(
                          "INICIAR SESIÓN",
                          style: TextStyle(color: Colors.white),
                        )),
                  ),

                  // Botón de registro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("¿No tienes una cuenta?"),
                      TextButton(
                          onPressed: () {
                            // Navegar a registrarse
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SignUp()));
                          },
                          child: const Text("REGÍSTRATE"))
                    ],
                  ),

                  // Desactivaremos este mensaje por defecto, cuando el usuario y la contraseña sean incorrectos, activaremos este mensaje para el usuario
                  isLoginTrue == false
                      ? const Text(
                          "El nombre de usuario o la contraseña son incorrectos",
                          style: TextStyle(color: Colors.red),
                        )
                      : const SizedBox(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
