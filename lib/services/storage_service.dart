import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  static Future<String?> downloadFile(String fileUrl) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(fileUrl);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${ref.name}');
      await ref.writeToFile(file);
      return file.path;
    } catch (e) {
      print("Error downloading file: $e");
      return null;
    }
  }
}
