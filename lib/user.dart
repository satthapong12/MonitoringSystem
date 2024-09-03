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
    static Future<String> setEmail(String email) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString("Email", email);
    return email;
  }
  static Future<String?> getEmail() async{
    SharedPreferences pref = await SharedPreferences.getInstance();{}
    return pref.getString("Email");
  }

  static saveSettings(String ip, String port) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('ip', ip);
  await prefs.setString('port', port);
  // คุณสามารถเพิ่มโค้ดเพิ่มเติมตามที่คุณต้องการ
}
 static Future<Map<String, String?>> getSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ip = prefs.getString('ip');
    String? port = prefs.getString('port');
    return {'ip': ip, 'port': port};
  }

 static Future<void> checkLoginStatus() async {
    String? email = await getEmail();
    if (email != null) {
      print("อีเมลที่ล็อกอินอยู่: $email");
      // ดำเนินการต่อไปกับข้อมูลที่ได้จากการล็อกอิน
    } else {
      print("ไม่มีข้อมูลอีเมลใน shared preferences");
      // ดำเนินการให้ผู้ใช้ล็อกอินใหม่
    }
  }

  static Future<void> fetchAndPrintSettings() async {
  // ดึงข้อมูลการตั้งค่าจาก SharedPreferences
  Map<String, String?> settings = await User.getSettings();
  
  // แสดงผลข้อมูล IP และ Port
  String? ip = settings['ip'];
  String? port = settings['port'];
  
  print('IP Address: $ip');
  print('Port: $port');
}

}
