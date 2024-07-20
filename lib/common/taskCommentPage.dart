import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:taskermg/controllers/user_controller.dart';
import 'package:taskermg/controllers/taskCommentController.dart';
import 'package:taskermg/models/task.dart';
import 'package:taskermg/models/taskComment.dart';
import 'package:taskermg/common/widgets/commentPopup.dart';
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
  FileManager fileManager = FileManager();
  Map<int, bool> _isDownloading = {};

  @override
  void initState() {
    super.initState();
    _controller.fetchComments(widget.task.taskID!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comentarios de la Tarea'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Obx(() {
        return _controller.commentsList.isEmpty
            ? const Center(child: Text('No hay comentarios.'))
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
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCommentTile(TaskComment comment) {
    List<Attachment> attachments = _controller.attachmentsList
        .where(
            (attachment) => attachment.taskCommentID == comment.taskCommentID)
        .toList();

    return FutureBuilder<String>(
      future: UserController.getProfilePicture(comment.userID),
      builder: (context, snapshot) {
        String userpic = snapshot.data ?? '';
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
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: userpic.isEmpty
                        ? const AssetImage("Assets/images/profile.png")
                            as ImageProvider
                        : NetworkImage(userpic),
                    radius: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      comment.comment ?? '',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
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
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CommentPopup(
          onSubmit: (String comment, Map<String, dynamic>? file) async {
            if (comment.isEmpty) {
              Get.snackbar('Error', 'El comentario no puede estar vacío.');
              return;
            }

            await _controller.addComment(widget.task.taskID!, comment, file);
            await _controller.fetchComments(widget.task.taskID!);
          },
        );
      },
    );
  }

  Widget _buildAttachmentTile(Attachment attachment) {
    var fileIcon = Icons.attach_file;
    switch (attachment.type) {
      case 'pdf':
        fileIcon = Icons.picture_as_pdf;
        break;
      case 'doc':
      case 'docx':
        fileIcon = Icons.description;
        break;
      case 'xls':
      case 'xlsx':
        fileIcon = Icons.table_chart;
        break;
      case 'ppt':
      case 'pptx':
        fileIcon = Icons.slideshow;
        break;
      case 'txt':
        fileIcon = Icons.text_fields;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        fileIcon = Icons.image;
        break;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
        fileIcon = Icons.movie;
        break;
      case 'mp3':
      case 'wav':
      case 'wma':
        fileIcon = Icons.music_note;
        break;
    }

    var fileSize = attachment.size! / 1024 / 1024;
    var fileSizeString = fileSize > 1
        ? "${fileSize.toStringAsFixed(2)} MB"
        : "${(attachment.size! / 1024).toStringAsFixed(2)} KB";

    var downloadBTN = _isDownloading[attachment.attachmentID] == true
        ? Row(
            children: [
              const SizedBox(width: 5),
              Text(
                "Descargando...",
                style: const TextStyle(color: Colors.blue),
              ),
              CircularProgressIndicator(),
            ],
          )
        : Row(
            children: [
              const SizedBox(width: 5),
              Text(
                "Descargar ($fileSizeString)",
                style: const TextStyle(color: Colors.blue),
              ),
              IconButton(
                icon: const Icon(Icons.download),
                color: Colors.blue,
                onPressed: () async {
                  setState(() {
                    _isDownloading[attachment.attachmentID!] = true;
                  });
                  File localFile = await fileManager.downloadFile(
                      attachment.fileUrl!, attachment.name!, "attachments");
                  await Attachment.updateAttachmentLocalPath(
                      attachment.attachmentID!, localFile.path);
                  setState(() {
                    _isDownloading[attachment.attachmentID!] = false;
                  });
                  FileManager.openFile(localFile.path);
                },
              )
            ],
          );
    if (attachment.localPath != null) {
      downloadBTN = Row(
        children: [
          const SizedBox(width: 5),
          Text(
            "($fileSizeString)",
            style: const TextStyle(color: Colors.blue),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () {
        if (attachment.localPath != null) {
          FileManager.openFile(attachment.localPath!);
        }
      },
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(fileIcon, color: Colors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                attachment.name ?? '',
                style: const TextStyle(color: Colors.blue),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            downloadBTN ?? Container(),
          ],
        ),
      ),
    );
  }
}
