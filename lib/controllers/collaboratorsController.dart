import 'dart:convert';
import 'package:get/get.dart';
import 'package:taskermg/controllers/dbRelationscontroller.dart';
import 'package:taskermg/db/db_helper.dart';
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
    fetchCollaborators();
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
