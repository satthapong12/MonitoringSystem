import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:Monitoring/Service/local_notifcation.dart';
import 'package:Monitoring/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:connectivity/connectivity.dart';
import 'package:slider_captcha/slider_captcha.dart';
import 'main.dart';
import 'user.dart';
import 'Service/fetch_user_profile.dart';

class login extends StatefulWidget {
  const login({Key? key}) : super(key: key);

  @override
  State<login> createState() => _loginState();
}

class _loginState extends State<login> {
  final _formKey = GlobalKey<FormState>();

  bool? checklogin = false; 
  final SliderController _sliderController = SliderController(); // เพิ่ม controller ของ SliderCaptcha
  bool _isSliderVerified = false; // ตรวจสอบว่า slider ผ่านหรือไม่
  String _message = '';
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

Future<void> _signIn() async {
  Map<String, String?> settings = await User.getSettings();
  String? ip = settings['ip'];
  String? port = settings['port'];
  if (ip == null || ip.isEmpty || port == null || port.isEmpty) {
    await showPopup('Please set IP and Port before signing in');
    return;
  }

  String url = "http://$ip:$port/routes/login";

  try {
    final response = await http.post(Uri.parse(url), body: {
      'email': _emailController.text,
      'password': _passwordController.text,
    });

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['message'] == "Login successful.") {
        String token = data['token'];
         SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        print(token);
        await _showSliderCaptchaDialog();

        // หลังจากยืนยัน slider
        if (_isSliderVerified) {
          if (data['urole'] == "admin") {
            await User.seturole(true);
          } else {
            await User.seturole(false);
          }
          await User.setsigin(true);
          await User.setEmail(_emailController.text);
          await fetchUserProfile();
          await initializeService();
          await User.fetchAndPrintSettings();
          Navigator.pushNamed(context, 'home');
        } else {
         await showPopup('Please verify the slider first');
        }
      } else {
       await showPopup('Server Error: ${response.statusCode}');
      }
    } else {
      await showPopup('Invalid email or password');

    }
  } catch (e) {
    print('Error: $e');
    await showPopup('Please set IP and Port before signing in');
  }
}

Future<bool> _showSliderCaptchaDialog() async {
     // ลิสต์ของชื่อไฟล์ภาพ
    List<String> images = [
      "assets/mooto1.jpeg",
      "assets/mootoo2.jpeg",
      "assets/mootoo3.jpeg",
      // เพิ่มชื่อไฟล์ภาพอื่นๆ ที่ต้องการ
    ];

    // เลือกภาพแบบสุ่ม
    String randomImage = images[Random().nextInt(images.length)];
  bool isVerified = false;

  await showDialog(
    context: context,
  
    builder: (BuildContext context) {
      
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        content: Container(
          width: 550, // กำหนดความกว้างของ dialog
          height: 250, // กำหนดความสูงของ dialog
          child: SliderCaptcha(
            controller: _sliderController,
            image: Image.asset(
              randomImage,
              fit: BoxFit.contain,
            ),
            onConfirm: (bool value) {
              setState(() {
                _isSliderVerified = value;
                isVerified = value; // บันทึกผลการยืนยัน
              });
              Navigator.of(context).pop(); // ปิด dialog เมื่อยืนยัน
              return Future.value();
            },
          ),
        ),
      );
    },
  );

  return isVerified; // คืนค่าผลการยืนยัน
}
Future<void> showPopup(String message) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: Row(
          children: [
            Icon(Icons.notification_important, color: Colors.blue),
            SizedBox(width: 8),
            Text('เกิดข้อผิดพลาด', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            message,
            style: TextStyle(fontSize: 16),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'OK',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      );
    },
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, size: 30.0, color: Colors.blue),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  String? ip;
                  String? port;

                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                    title: Text('Settings',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'IP Address',
                            hintText: '0.0.0.0',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (value) {
                            ip = value;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Port',
                            hintText: '0000',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (value) {
                            port = value;
                          },
                        ),
                      ],
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      ElevatedButton(
                        child: Text('Save'),
                        onPressed: () async {
                          if (ip != null && port != null) {
                            await User.saveSettings(ip!, port!);
                          }
                          print(ip);
                          print(port);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          primary: Colors.blueAccent,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 5.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Brute Force Attack Monitoring System',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'from Web Access Log Files.',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  shadowColor: Colors.black.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 10.0),
                    child: TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your Email';
                        }
                        bool emailValid = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                            .hasMatch(value);
                        if (!emailValid) {
                          return 'Please enter a valid Email';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  shadowColor: Colors.black.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 10.0),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // เพิ่ม SliderCaptcha
                SizedBox(height: 15),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                            });
                            await _signIn();
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        },
                  child: _isLoading
                      ? CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text('Sign In'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}