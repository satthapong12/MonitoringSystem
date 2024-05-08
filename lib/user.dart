import 'package:shared_preferences/shared_preferences.dart';

class User{
  static bool isSignedIn = false;
  static String firstName = "";
  static String lastName = "";
  static String email = "";
  static String phone = "";
  static String description = "";
  static String password = "";

  static Future<void> setSignIn(bool value) async {
    isSignedIn = value;
  }
  static Future<bool?> getsignin() async{
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getBool("Sign-in");
  }
  static Future setsigin(bool signin) async{
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setBool("Sign-in", signin);
  }
}