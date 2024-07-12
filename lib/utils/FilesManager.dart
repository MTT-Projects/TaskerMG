//Controlador de archivos locales y descarga y subida de archivos a firebase storage

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:taskermg/firebase_options.dart';

// ...



class FilesManager {

  static Future<String> get localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> localFile(String filename) async {
    final path = await localPath;
    return File('$path/$filename');
  }

  //descargar archivo con headers de un token de autenticacion para cada usuario que generara firebase.
  static Future<File> downloadFile(String filename) async {
    final ref = FirebaseStorage.instance.ref().child(filename);
    final file = await localFile(filename);
    await ref.writeToFile(file);
    return file;
  }

  static Future<String> uploadFile(File file, String filename) async {
    final ref = FirebaseStorage.instance.ref().child(filename);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}