import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/utils/AppLog.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';

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

    
Future<File> downloadFile(String url, String fileName, String subfolder) async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      Directory subDir = Directory('${appDocDir.path}/$subfolder');

      // Check if the subdirectory exists, if not, create it
      if (!await subDir.exists()) {
        await subDir.create(recursive: true);
      }

      File file = File('${subDir.path}/$fileName');
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

  Future<String> copyFileToLocalPath(Map<String, dynamic> file, String subfolder) async {
    try {
      var finalName = file["name"];
      // Clamp file name to 100 characters
      if (file["name"].length > 100) {
        AppLog.d('File name too long, clamping to 100 characters');
        finalName = file["name"].substring(0, 100);
      }
      
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String dirPath = '${appDocDir.path}/$subfolder';
      Directory dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      File localFile = File('$dirPath/$finalName');
      AppLog.d('Local file path: ${localFile.path}');
      
      // Assuming file['path'] contains the original file path
      File originalFile = File(file['path']);
      await originalFile.copy(localFile.path);
      
      return localFile.path;
    } catch (e) {
      throw Exception('Error copying file to local path: $e');
    }
  }

  static Future<void> openFile(String filePath) async {
  AppLog.d("Opening file: $filePath");
  File file = File(filePath);
  
  if (await file.exists()) {
    final result = await OpenFile.open(filePath);
    if (result.type != ResultType.done) {
      throw Exception('Error opening file: ${result.message}');
    }
  } else {
    throw Exception('Error opening file: the $filePath file does not exist');
  }
}
}
