import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:taskermg/controllers/maincontroller.dart';
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
  final ScrollController _scrollController = ScrollController();
  String fileName = '';
  FileManager fileManager = FileManager();
  Map<int, bool> _isDownloading = {};
  Map<int, bool> _hasLocalPath = {};
  late Future<void> _fetchCommentsFuture;
  Map<int, bool> _isLongPressing = {};
  Map<int, String> _userNames = {};
  Map<int, String> _userPictures = {};

  @override
  void initState() {
    super.initState();
    _fetchCommentsFuture = _fetchComments();
  }

  Future<void> _fetchComments() async {
    await _controller.fetchComments(widget.task.taskID!);
    await _loadUserDetails();
    _scrollToBottom();
  }

  Future<void> _reloadComments() async {
    setState(() {
      _fetchCommentsFuture = _fetchComments();
    });
    await _fetchCommentsFuture;
  }

  Future<void> _loadUserDetails() async {
    for (var comment in _controller.commentsList) {
      if (!_userNames.containsKey(comment.userID)) {
        var userName = await UserController.getUserName(comment.userID);
        var userPic = await UserController.getProfilePicture(comment.userID);
        setState(() {
          _userNames[comment.userID!] = userName;
          _userPictures[comment.userID!] = userPic;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var isDarkMode = Theme.of(context).brightness == Brightness.dark;
   return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30.0),
            bottomRight: Radius.circular(30.0),
          ),
          child: AppBar(
            title: Text('Comentarios', style: TextStyle(color: AppColors.secTextColor)),
            backgroundColor: AppColors.secBackgroundColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.secTextColor),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      body:  FutureBuilder<void>(
        future: _fetchCommentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: Container(
                    height: 200,
                    child: Column(children: [
                      Lottie.asset('Assets/lotties/loading.json', width: 100),
                      const SizedBox(height: 25),
                      const Text('Cargando comentarios...'),
                    ])));
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar comentarios'),
            );
          } else {
            return Obx(() {
              return _controller.commentsList.isEmpty
                  ? const Center(child: Text('No hay comentarios.'))
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: false, // Scroll de abajo hacia arriba
                      itemCount: _controller.commentsList.length,
                      itemBuilder: (context, index) {
                        TaskComment comment =
                            _controller.commentsList.reversed.toList()[index];
                        return _buildCommentTile(comment);
                      },
                    );
            });
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.values[1],
            gradient: LinearGradient(
              colors: [AppColors.secondaryColor, AppColors.primaryColor],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(color: AppColors.backgroundColor, width: 3),
          ),
          child: Icon(
            Icons.add,
            size: 40,
          ),
        ),
        onPressed: () async {
          await _mostrarPopup(context);
          await _reloadComments();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        color: AppColors.secBackgroundColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(() {
              return Text(
                'Comentarios: ${_controller.commentsList.length}',
                style: TextStyle(
                  color: AppColors.secTextColor,
                ),
              );
            }),
            IconButton(
              icon: Icon(Icons.refresh, color: AppColors.secTextColor),
              onPressed: () async {
                await _reloadComments();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentTile(TaskComment comment) {
    List<Attachment> attachments = _controller.attachmentsList
        .where(
            (attachment) => attachment.taskCommentID == comment.taskCommentID)
        .toList();

    int currentUserID = MainController.getVar('currentUser');
    String userName = _userNames[comment.userID] ?? '';
    String userPic = _userPictures[comment.userID] ?? '';
    bool isMine = comment.userID == currentUserID;
    return GestureDetector(
      onLongPressStart: (_) {
        if (comment.userID == currentUserID) {
          setState(() {
            _isLongPressing[comment.locId ?? comment.taskCommentID ?? 0] = true;
          });
        }
      },
      onLongPressEnd: (_) {
        if (comment.userID == currentUserID) {
          setState(() {
            _isLongPressing[comment.locId ?? comment.taskCommentID ?? 0] =
                false;
          });
          _showDeleteDialog(context, comment);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isLongPressing[comment.locId ?? comment.taskCommentID ?? 0] ==
                  true
              ? Colors.red.withOpacity(0.5)
              : Colors.white,
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
                  backgroundImage: userPic.isEmpty
                      ? const AssetImage("Assets/images/profile.png")
                          as ImageProvider
                      : NetworkImage(userPic),
                  radius: 20,
                ),
                const SizedBox(width: 10),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
              ],
              mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  comment.comment ?? '',
                  style: const TextStyle(fontSize: 16),
                  textAlign: isMine ? TextAlign.end : TextAlign.start,
                ),
              ],
              mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
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
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, TaskComment comment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Eliminar Comentario'),
          content:
              Text('¿Estás seguro de que quieres eliminar este comentario?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await TaskCommentController.deleteComment(comment);
                await _reloadComments();
                Navigator.of(context).pop();
              },
              child: Text('Eliminar'),
              style: ElevatedButton.styleFrom(
                primary: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarPopup(BuildContext context) async {
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

            await _reloadComments();
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

    if (attachment.localPath != null) {
      _hasLocalPath[attachment.locId!] = true;
    }

    var downloadBTN = _hasLocalPath[attachment.locId] == true
        ? Row(
            children: [
              const SizedBox(width: 5),
              Text(
                "($fileSizeString)",
                style: const TextStyle(color: Colors.blue),
              ),
            ],
          )
        : _isDownloading[attachment.locId] == true
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
                        _isDownloading[attachment.locId!] = true;
                      });
                      File localFile = await fileManager.downloadFile(
                          attachment.fileUrl!, attachment.name!, "attachments");
                      await Attachment.updateAttachmentLocalPath(
                          attachment.locId!, localFile.path);
                      setState(() {
                        _isDownloading[attachment.locId!] = false;
                        _hasLocalPath[attachment.locId!] = true;
                        attachment.localPath = localFile.path;
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
            downloadBTN,
          ],
        ),
      ),
    );
  }
}
