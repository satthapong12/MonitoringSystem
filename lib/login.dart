import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:monitoringsystem/Service/local_notifcation.dart';
import 'package:monitoringsystem/home.dart';
import 'dart:convert';
import 'package:connectivity/connectivity.dart';
import 'main.dart';
import 'user.dart';
import 'Service/fetch_user_profile.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';

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
  bool isLoading = false;
  bool captchaVerified = false;
  bool showCaptcha = true;

  Future sing_in() async {
    String url = "http://192.168.1.104:3001/login";

    final response = await http.post(Uri.parse(url), body: {
      'email': email.text,
      'password': pass.text,
    });
    var data = json.decode(response.body);
    print(data);
    if (data == "Error") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid email or password')),
      );
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

  Future<bool> checkNetwork() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
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
                  if (showCaptcha)
                    Center(
                      child: SizedBox(
                        height: 300,
                        width: 350, // Adjust width as needed
                        child: WebViewPlus(
                          javascriptMode: JavascriptMode.unrestricted,
                          onWebViewCreated: (controller) {
                            controller.loadUrl('assets/webpages/index.html');
                          },
                          javascriptChannels: Set.from({
                            JavascriptChannel(
                              name: 'Captcha',
                              onMessageReceived: (JavascriptMessage message) {
                                setState(() {
                                  captchaVerified = true;
                                });
                              },
                            ),
                          }),
                        ),
                      ),
                    ),
                  SizedBox(
                    height: 5,
                  ),
                  SizedBox(
                    width: 350,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: const Color(0xFF3F60A0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () async {
                        bool valid = formkey.currentState!.validate();
                        if (valid) {
                          if (!showCaptcha) {
                            setState(() {
                              showCaptcha = true;
                            });
                          } else if (captchaVerified) {
                            bool network = await checkNetwork();
                            if (network) {
                              setState(() {
                                isLoading = true;
                              });
                              await sing_in();
                              await initializeService();
                              setState(() {
                                isLoading = false;
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('No internet connection')),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Please complete the captcha')),
                            );
                          }
                        }
                      },
                      child: isLoading
                          ? CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            )
                          : const Text(
                              'Sign in',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
