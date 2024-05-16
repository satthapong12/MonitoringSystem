import 'package:flutter/material.dart';
import 'user.dart';

class check_login extends StatefulWidget {
  const check_login({Key? key}) : super(key: key);

  @override
  State<check_login> createState() => CheckLoginState();
}

class CheckLoginState extends State<check_login> {
  Future<void> checklogin() async {
    bool? sigin = await User.getsignin();
    print("CheckLogin: $sigin");
    if (sigin == false) {
      Navigator.pushNamed(context, 'login');
    } else {
      print("CheckLogin: $sigin");

      Navigator.pushNamed(context, 'home');
    }
  
  }

  @override
  void initState() {
    checklogin();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
