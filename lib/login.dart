// ignore_for_file: prefer_const_constructors, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:monitoringsystem/Service/local_notifcation.dart';
import 'dart:convert';
import 'main.dart';
import 'user.dart';
import 'Service/fetch_user_profile.dart';

class login extends StatefulWidget {
  const login({Key? key}) : super(key: key);

  @override
  State<login> createState() => _loginState();
}

class _loginState extends State<login> {
  final formkey = GlobalKey<FormState>();

  bool? checklogin = false;
  String srt = '';
  TextEditingController email = TextEditingController();
  TextEditingController pass = TextEditingController();

  Future sing_in() async {
    //  String url = "http://127.0.0.1/flutter_login/login.php";
    String url = "http://192.168.1.100/flutter_login/login.php";

    final response = await http.post(Uri.parse(url), body: {
      'email': email.text,
      'password': pass.text,
    });
    var data = json.decode(response.body);
    print(data);
    if (data == "Error") {
      Navigator.pushNamed(context, 'login');
    } else {
      await User.setsigin(true);
      print("เข้าสู่ระบบสำเร็จ");
      String? str = await User.setEmail(email.text);
      print(str);
      await fetchUserProfile(email.text);
      Navigator.pushNamed(context, 'home');
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: Center(
        child: Form(
          key: formkey,
          child: ListView(
            shrinkWrap: true,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Welcome !',
                    style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    'A Brute Force Attack Monitoring System ',
                    style: TextStyle(fontSize: 20),
                  ),
                  Text(
                    'from Web Access Log Files.',
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  //Image.asset('assets/img/Picture.png'),
                  SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    width: 350,
                    child: TextFormField(
                      controller: email,
                      obscureText: false,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Email',
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your Email';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    width: 350,
                    child: TextFormField(
                      controller: pass,
                      obscureText: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Password',
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    width: 350,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          primary: const Color(0xFF3F60A0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15))),
                      onPressed: () async {
                        bool pass = formkey.currentState!.validate();
                        if (pass) {
                          sing_in();
                          await initializeService();
                        }
                      },
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  //TextButton(
                  //style: TextButton.styleFrom(
                  //textStyle: const TextStyle(fontSize: 15),
                  //),
                  //onPressed: () {
                  //Navigator.pushNamed(context, 'register');
                  //},S
                  //child: const Text("Didn't have any Account? Sign Up now"),
                  //),
                ],
              ),
            ],
          ),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
