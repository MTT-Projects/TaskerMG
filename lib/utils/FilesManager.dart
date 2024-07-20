import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';

class FileManager {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = Uuid();

  Future<String> uploadFile(File file, String userId, String fileName, String subfolder) async {
    try {
      //clamp file name to 100 characters
      if (fileName.length > 100) {
        fileName = fileName.substring(0, 100);
      }
      Reference ref = _storage.ref().child('$userId/$subfolder/$fileName');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }

    Future<String> uploadAttatchment(File file, String userId, String fileName) async {
    try {
      Reference ref = _storage.ref().child('profile_pics/$userId/$fileName');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }


  Future<File> downloadFile(String url, String fileName) async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File file = File('${appDocDir.path}/$fileName');
      if (!await file.exists()) {
        await file.create();
      }
      await _storage.refFromURL(url).writeToFile(file);
      return file;
    } catch (e) {
      throw Exception('Error downloading file: $e');
    }
  }

  Future<File> saveFileLocally(File file, String fileName) async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File localFile = File('${appDocDir.path}/$fileName');
      return await file.copy(localFile.path);
    } catch (e) {
      throw Exception('Error saving file locally: $e');
    }
  }

  static Future<Map<String, dynamic>?> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.single != null) {
        PlatformFile file = result.files.single;
        return {
          'path': file.path,
          'name': file.name,
          'type': file.extension,
          'size': file.size,
          'file': File(file.path!),
        };
      } else {
        // User canceled the picker
        return null;
      }
    } catch (e) {
      print("Error picking file: $e");
      return null;
    }
  }

  Future<String> copyFileToLocalPath(Map<String, dynamic>file, subfolder) async {
    try {
      //clamp file name to 100 characters
      if (file["name"].length > 100) {
        file["name"] = file["name"].substring(0, 100);
      }
      var currentUserID = MainController.getVar('currentUser').toString();
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File localFile = File('${appDocDir.path}/$subfolder/${file["name"]}');
      return localFile.path;
    } catch (e) {
      throw Exception('Error copying file to local path: $e');
    }

  }
}
