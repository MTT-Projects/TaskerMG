import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:googleapis/adsense/v2.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Perfil'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _user != null
            ? Column(
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
                      'Bienvenido, ${_user?.username}',
                      style: headingStyle,
                    ),
                    SizedBox(height: 20),
                    GestureDetector(
                      onTap: () async {
                        //diable all the buttons

                        await _controller.pickImage(context);
                        _loadUserData();

                      },
                      child: CircleAvatar(
                        radius: 150,
                        backgroundImage: _user?.profileData?['profilePicUrl'] != null
                            ? NetworkImage(_user?.profileData?['profilePicUrl'])
                                as ImageProvider<Object>?
                            : const AssetImage('Assets/images/profile.png'),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Icon(Icons.camera_alt, color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "¿Cuál es tu nombre?",
                      style: subHeadingStyle,
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: 'Nombre'),
                      controller: _nameController,
                      onChanged: (value) {
                        _user?.name = value;
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: Text('Guardar'),
                    ),
                  ],
                ),
              )
            : Center(child: CircularProgressIndicator()),
      ),
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
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => Splash()));
      
    } catch (e) {
      // Handle error
    }
  }
}
