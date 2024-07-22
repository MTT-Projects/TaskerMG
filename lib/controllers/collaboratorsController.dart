import 'dart:convert';
import 'package:get/get.dart';
import 'package:taskermg/api/firebase_api.dart';
import 'package:taskermg/controllers/dbRelationscontroller.dart';
import 'package:taskermg/controllers/maincontroller.dart';
import 'package:taskermg/controllers/project_controller.dart';
import 'package:taskermg/controllers/sync_controller.dart';
import 'package:taskermg/controllers/user_controller.dart';
import 'package:taskermg/db/db_helper.dart';
import 'package:taskermg/utils/AppLog.dart';
import '../models/user.dart';

class CollaboratorsController extends GetxController {
  var collaboratorsList = <User>[].obs;
  var searchQuery = ''.obs;

  int? projectId;

  CollaboratorsController({this.projectId});

  @override
  void onInit() {
    super.onInit();
    fetchCollaborators();
  }

  void fetchCollaborators() async {
    var result = await DBHelper.query('''
        SELECT u.*, 
                pd.profilePicUrl, 
                pd.profileDataID,
                pd.lastUpdate as profileLastUpdate
        FROM user u
        JOIN userProject up ON u.userID = up.userID
        LEFT JOIN profileData pd ON u.userID = pd.userID
        WHERE up.projectID = ?
  ''', [projectId]);

    List<User> collaborators = result.map<User>((data) {
      var profileData = {
        'profileDataID': data['profileDataID'],
        'profilePicUrl': data['profilePicUrl'],
        'lastUpdate': data['profileLastUpdate']
      };
      var userData = {
        'userID': data['userID'],
        'username': data['username'],
        'name': data['name'],
        'email': data['email'],
        'password': data['password'],
        'creationDate': data['creationDate'],
        'salt': data['salt'],
        'lastUpdate': data['lastUpdate'],
        'firebaseToken': data['firebaseToken'],
        'profileData': profileData
      };
      return User.fromJsonWithProfile(userData);
    }).toList();

    collaboratorsList.value = collaborators;
  }

  void addCollaborator(User user) async {
    await DbRelationsCtr.addUserProject(user.userID, projectId);
    await SyncController.pushData();
    fetchCollaborators();
    sendInviteNotification(user.email);
  }

  //get profileData by ID else return null
  static Future<Map<String, dynamic>?> getProfileDataById(
      int profileDataID) async {
    var result = await DBHelper.query(
      'SELECT * FROM profileData WHERE profileDataID = ?',
      [profileDataID],
    );
    if (result.isNotEmpty) {
      var retprofile = {
        'profileDataID': result.first['profileDataID'],
        'profilePicUrl': result.first['profilePicUrl'],
        'lastUpdate': result.first['lastUpdate']
      };
      return retprofile;
    } else {
      return null;
    }
  }

  static Future<User?> getCollaboratorByEmail(String email) async {
    var projectID = MainController.getVar('currentProject');
    var result = await DBHelper.query(
      ''' 
        SELECT u.*, 
           pd.profilePicUrl, 
           pd.profileDataID,
           pd.lastUpdate as profileLastUpdate
        FROM 
          user u
        LEFT JOIN 
          profileData pd ON u.userID = pd.userID
        JOIN 
          userProject up ON u.userID = up.userID
        WHERE 
          u.email = ? 
          AND up.projectID = ? 
        ''',
      [email, projectID],
    );
    if (result.isNotEmpty) {
      var userResult = result.first;
      var userMapped = {
        'userID': userResult['userID'],
        'username': userResult['username'],
        'name': userResult['name'],
        'email': userResult['email'],
        'password': userResult['password'],
        'creationDate': userResult['creationDate'],
        'salt': userResult['salt'],
        'lastUpdate': userResult['lastUpdate'],
        'firebaseToken': userResult['firebaseToken'],
        'profileData': {
          'profileDataID': userResult['profileDataID'],
          'profilePicUrl': userResult['profilePicUrl'],
          'lastUpdate': userResult['profileLastUpdate']
        }
      };

      return User.fromJsonWithProfile(userMapped);
    } else {
      return null;
    }
  }

  static Future<void> sendInviteNotification(email) async {
    var currentUser = MainController.getVar('currentUser');
    //get currentuser name
    var username = await UserController.getUserName(currentUser);
    var projectname = await ProjectController.getProjectName(
        MainController.getVar('currentProject'));

    var user = await getUserWithEmail(email);
    if (user != null) {
      AppLog.d('User found: ${user.name}');
      AppLog.d('Send notification task started');
      var firebasetoken = await UserController.getFirebaseToken(email);
      if (firebasetoken != null) {
        AppLog.d('Firebase token: $firebasetoken');
        await FirebaseApi.sendNotification(
            to: firebasetoken,
            title: "Invitacion a proyecto",
            body: "$username te ha invitado al proyecto $projectname",
            data: {
              'type': 'invite',
              'projectID': MainController.getVar('currentProject').toString(),
              'projectName': projectname,
              'invitedBy': username
            });
      } else {
        AppLog.d('Firebase token not found');
      }
    } else {
      AppLog.d('User not found');
    }
  }

  static Future<User?> getUserWithEmail(String email) async {
    var result = await DBHelper.query(
      ''' SELECT u.*, 
           pd.profilePicUrl, 
           pd.profileDataID,
           pd.lastUpdate as profileLastUpdate
    FROM user u
    LEFT JOIN profileData pd ON u.userID = pd.userID
    WHERE u.email= ?''',
      [email],
    );
    if (result.isNotEmpty) {
      var userResult = result.first;
      var userMapped = {
        'userID': userResult['userID'],
        'username': userResult['username'],
        'name': userResult['name'],
        'email': userResult['email'],
        'password': userResult['password'],
        'creationDate': userResult['creationDate'],
        'salt': userResult['salt'],
        'lastUpdate': userResult['lastUpdate'],
        'firebaseToken': userResult['firebaseToken'],
        'profileData': {
          'profileDataID': userResult['profileDataID'],
          'profilePicUrl': userResult['profilePicUrl'],
          'lastUpdate': userResult['profileLastUpdate']
        }
      };

      return User.fromJsonWithProfile(userMapped);
    } else {
      return null;
    }
  }

  void removeCollaborator(int userId) async {
    await DBHelper.query(
      'DELETE FROM userProject WHERE userID = ? AND projectID = ?',
      [userId, projectId],
    );
    fetchCollaborators();
  }

  void filterCollaborators(String query) {
    searchQuery.value = query;
  }

  List<User> get filteredCollaborators {
    if (searchQuery.value.isEmpty) {
      return collaboratorsList;
    } else {
      return collaboratorsList.where((collaborator) {
        return collaborator.name!
                .toLowerCase()
                .contains(searchQuery.value.toLowerCase()) ||
            collaborator.email
                .toLowerCase()
                .contains(searchQuery.value.toLowerCase());
      }).toList();
    }
  }
}
