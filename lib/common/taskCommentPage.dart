import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:taskermg/controllers/user_controller.dart';
import 'package:taskermg/controllers/taskCommentController.dart';
import 'package:taskermg/models/task.dart';
import 'package:taskermg/models/taskComment.dart';
import 'package:taskermg/models/attachment.dart';
import 'package:taskermg/common/theme.dart';
import 'package:taskermg/utils/FilesManager.dart';

class TaskCommentsPage extends StatefulWidget {
  final Task task;

  TaskCommentsPage({required this.task});

  @override
  _TaskCommentsPageState createState() => _TaskCommentsPageState();
}

class _TaskCommentsPageState extends State<TaskCommentsPage> {
  final TaskCommentController _controller = Get.put(TaskCommentController());
  String fileName = '';
  var SelectedFile;

  @override
  void initState() {
    super.initState();
    _controller.fetchComments(widget.task.taskID!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comentarios de la Tarea'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Obx(() {
        return _controller.commentsList.isEmpty
            ? Center(child: Text('No hay comentarios.'))
            : ListView.builder(
                itemCount: _controller.commentsList.length,
                itemBuilder: (context, index) {
                  TaskComment comment = _controller.commentsList[index];
                  return _buildCommentTile(comment);
                },
              );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mostrarPopup(context);
        },
        child: Icon(Icons.add),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  Widget _buildCommentTile(TaskComment comment) {
    List<Attachment> attachments = _controller.attachmentsList
        .where(
            (attachment) => attachment.taskCommentID == comment.taskCommentID)
        .toList();
    var userpic = UserController.getProfilePicture(comment.userID);
    var userName = UserController.getUserName(comment.userID);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: userpic != null
                    ? NetworkImage(userpic)
                    : AssetImage("Assets/images/user.png") as ImageProvider,
                radius: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  comment.comment ?? '',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (attachments.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: attachments.map((attachment) {
                return _buildAttachmentTile(attachment);
              }).toList(),
            ),
          const SizedBox(height: 5),
          Text(
            DateFormat('dd-MM-yyyy HH:mm')
                .format(comment.creationDate ?? DateTime.now()),
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _mostrarPopup(BuildContext context) {
    final TextEditingController textController = TextEditingController();
    SelectedFile = null;
    fileName = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Enviar Comentario',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
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
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        SelectedFile = await FileManager.pickFile();
                        setState(() {
                          fileName = SelectedFile["name"];
                        });
                      },
                      icon: fileName.isEmpty
                          ? Icon(Icons.attach_file)
                          : Icon(Icons.check),
                      label: Text('Adjuntar Archivo'),
                      style: ElevatedButton.styleFrom(
                        primary: fileName.isEmpty
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
                            style: TextStyle(color: Colors.grey),
                          )
                        : Container(),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Cerrar el popup
                          },
                          child: Text('Cancelar'),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Aquí puedes implementar la lógica para enviar el formulario
                          },
                          child: Text('Enviar'),
                          style: ElevatedButton.styleFrom(
                            primary: AppColors.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String pickFile(AboutDialog aboutDialog) {
    throw UnimplementedError();
  }

  Widget _buildAttachmentTile(Attachment attachment) {
    return GestureDetector(
      onTap: () {
        // Implementa la lógica para descargar el archivo
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.attach_file, color: Colors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                attachment.name ?? '',
                style: TextStyle(color: Colors.blue),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.download, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}
