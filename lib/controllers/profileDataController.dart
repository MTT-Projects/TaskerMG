
import 'package:get/get.dart';
import 'package:taskermg/db/db_helper.dart';

import '../models/user.dart';

class ProfileDataController extends GetxController {
    static Future<Map<String, dynamic>?> getProfileDataByUserID(int userID) async {
    var result = await DBHelper.query(
      'SELECT * FROM profileData WHERE userID = ?',
      [userID],
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

  static Future<User?> getUserById(int userId) async {
    var result = await DBHelper.query(
      ''' SELECT u.*, 
           pd.profilePicUrl, 
           pd.profileDataID,
           pd.lastUpdate as profileLastUpdate
    FROM user u
    LEFT JOIN profileData pd ON u.userID = pd.userID
    WHERE u.userID= ?''',
      [userId],
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
    }    
    else {
      return null;
    }
  }

}