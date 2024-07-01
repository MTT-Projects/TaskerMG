// ignore_for_file: use_build_context_synchronously

import 'package:dos/controllers/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/login.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          height: 55,
          width: MediaQuery.of(context).size.width * .9,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8), color: Colors.deepPurple),
          child: TextButton(
              onPressed: () async {
                await UserController.logout();
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const LoginScreen()));
              },
              child: const Text(
                "LogOut",
                style: TextStyle(color: Colors.white),
              )),
        ),
      ),
    );
  }
}
