// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, sort_child_properties_last, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taskermg/auth/login.dart';
import 'package:taskermg/common/widgets/splash.dart';
import 'package:taskermg/controllers/ProfileEditController.dart';
import 'package:taskermg/controllers/profileDataController.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/db/db_local.dart';
import 'package:taskermg/models/user.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/common/theme.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final ProfileEditController _controller = ProfileEditController();
  User? _user;
  late TextEditingController _nameController;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    int currentUserId = MainController.getVar('currentUser') ?? 0;
    var loadUser = await ProfileDataController.getUserById(currentUserId);
    _user = loadUser as User;
    _nameController = TextEditingController(text: _user?.name);
    setState(() {
      _user = loadUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    double profileImageSize = MediaQuery.of(context).viewInsets.bottom == 0 ? 150.0 : 100.0;

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
            title: Text('Editar Perfil', style: TextStyle(color: AppColors.secTextColor)),
            backgroundColor: AppColors.secBackgroundColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.secTextColor),
              onPressed: () {
                //back to previous screen if exists
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            Text(
              'Bienvenido, ${_user?.username}',
              style: headingStyle,
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: _isUploading ? null : () async {
                setState(() {
                  _isUploading = true;
                });
                await _controller.pickImage(context);
                _loadUserData();
                setState(() {
                  _isUploading = false;
                });
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: profileImageSize,
                    backgroundImage: _user?.profileData?['profilePicUrl'] != null
                        ? NetworkImage(_user?.profileData?['profilePicUrl'])
                            as ImageProvider<Object>?
                        : const AssetImage('Assets/images/profile.png'),
                  ),
                  if (_isUploading)
                    Container(
                      width: profileImageSize,
                      height: profileImageSize,
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 10),
                          Text(
                            'Subiendo...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 375),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: widget,
                    ),
                  ),
                  children: [
                    Text(
                      "¿Cuál es tu nombre?",
                      style: subHeadingStyle,
                    ),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                      controller: _nameController,
                      onChanged: (value) {
                        _user?.name = value;
                      },
                    ),
                    SizedBox(height: 20),
                    // Aquí puedes agregar más campos de datos en el futuro.
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _saveProfile,
        child: Icon(Icons.save),
        backgroundColor: AppColors.secondaryColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> _saveProfile() async {
    try {
      User builUser = User(
        userID: _user?.userID,
        username: _user!.username,
        name: _nameController.text,
        email: _user!.email,
        password: _user!.password,
        creationDate: _user?.creationDate,
        lastUpdate: DateTime.now(),
        firebaseToken: _user?.firebaseToken,
      );
      await DBHelper.query(
        "UPDATE user SET name = ? WHERE userID = ?",
        [builUser.name, builUser.userID],
      );
      await LocalDB.updateUser(builUser);
      //Goto dashboard
      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (context) => Splash()),
          (Route<dynamic> route) => false);
    } catch (e) {
      // Handle error
    }
  }
}
