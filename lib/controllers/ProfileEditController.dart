import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/models/user.dart';
import 'package:taskermg/utils/AppLog.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/controllers/user_controller.dart';
import 'package:taskermg/common/widgets/popUpDialog.dart';
import 'package:taskermg/utils/FilesManager.dart';

class ProfileEditController {
  final ImagePicker _picker = ImagePicker();
  FileManager fileManager = FileManager();

  Future<void> pickImage(BuildContext context) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        String userId = MainController.getVar('currentUser').toString();
        String downloadUrl = await fileManager.uploadFile(imageFile, userId, 'profile_$userId.png', 'profile_pics');
        await fileManager.saveFileLocally(imageFile, 'profile_$userId.png');
        await updateUserProfilePic(userId, downloadUrl);
      }
    } catch (e) {
      AppLog.e("Error picking image: $e");
      showDialog(
        context: context,
        builder: (context) {
          return PopUpDialog(
            title: "Error",
            text: "Error picking image: $e",
            icon: Icons.error,
            buttons: PopUpButtons.okButton(context),
          );
        },
      );
    }
  }

  Future<void> updateUserProfilePic(String userId, String downloadUrl) async {
    try {
      await UserController.updateUserProfilePic(userId, downloadUrl);
    } catch (e) {
      throw Exception('Error updating profile picture: $e');
    }
  }
}
