import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:get/get.dart';
import 'package:taskermg/common/theme.dart';
import 'package:taskermg/controllers/taskCommentController.dart';
import 'package:taskermg/utils/FilesManager.dart';

class CommentPopup extends StatefulWidget {
  final Function(String, Map<String, dynamic>?) onSubmit;

  CommentPopup({required this.onSubmit});

  @override
  _CommentPopupState createState() => _CommentPopupState();
}

class _CommentPopupState extends State<CommentPopup> {
  final TextEditingController textController = TextEditingController();
  Map<String, dynamic>? selectedFile;
  String fileName = '';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: isLoading
            ? Container(
                height: 200,
                width: 200,
                child: Center(
                  child: Lottie.asset('Assets/lotties/sending.json'),
                ))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enviar Comentario',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      labelText: 'Comentario',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      selectedFile = await FileManager.pickFile();
                      setState(() {
                        if (selectedFile != null) {
                          fileName = selectedFile!["name"];
                        }
                      });
                    },
                    icon: fileName.isEmpty
                        ? const Icon(Icons.attach_file)
                        : const Icon(Icons.check),
                    label: const Text('Adjuntar Archivo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: fileName.isEmpty
                          ? AppColors.primaryColor
                          : Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  fileName.isNotEmpty
                      ? Text(
                          fileName,
                          style: const TextStyle(color: Colors.grey),
                        )
                      : Container(),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Cerrar el popup
                        },
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isLoading = true;
                          });
                          await widget.onSubmit(
                              textController.text, selectedFile);
                          setState(() {
                            isLoading = false;
                          });
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: const Text('Enviar'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
