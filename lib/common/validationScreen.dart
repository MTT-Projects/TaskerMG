import 'package:flutter/material.dart';
import 'package:taskermg/common/widgets/splash.dart';
import 'package:taskermg/services/MailService.dart';
import 'package:taskermg/controllers/user_controller.dart';
import 'package:taskermg/common/theme.dart';
import 'package:get/get.dart';

class ValidationScreen extends StatefulWidget {
  final String email;
  final int userId;

  const ValidationScreen({required this.email, required this.userId});

  @override
  _ValidationScreenState createState() => _ValidationScreenState();
}

class _ValidationScreenState extends State<ValidationScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyCode() async {
    setState(() {
      _isLoading = true;
    });

    bool isValid = await UserController.verifyValidationCode(
        widget.userId, _codeController.text);

    setState(() {
      _isLoading = false;
    });

    if (isValid) {
      _showPopup(
          'Validación exitosa', 'Tu cuenta ha sido validada exitosamente.');
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (context) => Splash()));
    } else {
      _showPopup('Error de validación', 'El código ingresado es incorrecto.');
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isLoading = true;
    });

    int newCode = await UserController.generateValidationCode(widget.userId);
    await MailService.sendMail(
      to: widget.email,
      subject: 'Tu nuevo código de verificación',
      code: newCode.toString(),
    );

    setState(() {
      _isLoading = false;
    });

    _showPopup('Código reenviado',
        'Se ha enviado un nuevo código de verificación a tu correo electrónico.');
  }

  void _showPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.all(30.0),
                      padding: const EdgeInsets.all(10.0),
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(75),
                        border: Border.all(color: Colors.deepPurple, width: 5),
                      ),
                      child: Image.network(
                        'https://raw.githubusercontent.com/Matiw172/matiw172.github.io/main/images/MTT_Logo_complet.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Verificación de Correo Electrónico',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ingresa el código de verificación que se ha enviado a tu correo electrónico.',
                      style: TextStyle(
                          fontSize: 16, color: AppColors.secTextColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: 'Código de Verificación',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _verifyCode,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        primary: AppColors.primaryColor,
                      ),
                      child: Text('Verificar',
                          style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: _resendCode,
                      child: Text('Reenviar Código',
                          style: TextStyle(
                              fontSize: 16, color: AppColors.primaryColor)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
