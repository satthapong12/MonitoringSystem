import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:Monitoring/Service/local_notifcation.dart';
import 'package:Monitoring/home.dart';
import 'dart:convert';
import 'package:connectivity/connectivity.dart';
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
  String _message = '';
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _uroleController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

int _failedAttempts = 0;
final int _maxAttempts = 3;
bool _isCoolingDown = false;
Timer? _coolDownTimer;
int _coolDownDuration = 5 * 60; // 5 นาทีเป็นวินาที
int _coolDownRemaining = 0; // ใช้ติดตามเวลาที่เหลือในช่วง coolDown

Future<void> _signIn() async {
  Map<String, String?> settings = await User.getSettings();
  String? ip = settings['ip'];
  String? port = settings['port'];
  if (ip == null || ip.isEmpty || port == null || port.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please set IP and Port before signing in')),
    );
    return;
  }

  String url = "http://$ip:$port/login";

  try {
    final response = await http.post(Uri.parse(url), body: {
      'email': _emailController.text,
      'password': _passwordController.text,
    });

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['urole'] == "admin") {
        await User.seturole(true);
      } else {
        await User.seturole(false);
      }
      if (data['message'] == "Login Successful. OTP sent to your email.") {
        // แสดง dialog หรือหน้าจอให้ผู้ใช้กรอก OTP
        _showOtpDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid email or password')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server Error: ${response.statusCode}')),
      );
    }
  } catch (e) {
    print('Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An unexpected error occurred')),
    );
  }
}

  Future<bool> _checkNetwork() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }
void _showOtpDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 60,
                  color: Colors.blueGrey,
                ),
                SizedBox(height: 16),
                Text(
                  'Enter OTP',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                SizedBox(height: 16),
                if (_isCoolingDown) // แสดงเวลาที่เหลือหากอยู่ในช่วง coolDown
                  Text(
                    'Cooldown active. Time remaining: ${_formatRemainingTime()}',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  )
                else // แสดงจำนวนครั้งที่กรอกผิด
                  Text(
                    'Invalid OTP attempts left: ${_maxAttempts - _failedAttempts}',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                TextField(
                  controller: _otpController,
                  decoration: InputDecoration(
                    hintText: 'Enter OTP sent to your email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    TextButton(
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    ElevatedButton(
                      child: Text('Verify'),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blue,
                        onPrimary: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      onPressed: () async {
                        String otp = _otpController.text;
                        if (await _verifyOtp(otp)) {
                          await User.setsigin(true);
                          await User.setEmail(_emailController.text);
                          await fetchUserProfile();
                          await initializeService();
                          await User.fetchAndPrintSettings();
                          Navigator.pushNamed(context, 'home');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Invalid OTP')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}



Future<bool> _verifyOtp(String otp) async {

    if (_isCoolingDown) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You are in cooldown period. Please try again later.')),
    );
    return false;
  }

  Map<String, String?> settings = await User.getSettings();
  String? ip = settings['ip'];
  String? port = settings['port'];


   String url = "http://$ip:$port/login/verify";

  try {
    final response = await http.post(Uri.parse(url), body: {
      'email': _emailController.text,
      'otp': otp,
    });

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['message'] == 'OTP verified successfully') {
        _failedAttempts = 0; // Reset failed attempts on successful OTP verification
        return true;
      } else {
        setState(() {
                  _failedAttempts++;

        });
        if (_failedAttempts >= _maxAttempts) {
          _startCoolDown();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid OTP')),
        );
        return false;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server Error: ${response.statusCode}')),
      );
      return false;
    }
  } catch (e) {
    print('Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An unexpected error occurred')),
    );
    return false;
  }
}
void _startCoolDown() {
  _isCoolingDown = true;
  _coolDownRemaining = _coolDownDuration; // ตั้งเวลาของ coolDown
  _coolDownTimer?.cancel();
  _coolDownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
    if (_coolDownRemaining > 0) {
      setState(() {
        _coolDownRemaining--;
      });
    } else {
      timer.cancel();
      setState(() {
        _isCoolingDown = false;
        _failedAttempts = 0;
      });
    }
  });
}
String _formatRemainingTime() {
  int minutes = _coolDownRemaining ~/ 60;
  int seconds = _coolDownRemaining % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
                  title: Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
            mainAxisAlignment: MainAxisAlignment.start, // เพิ่มการจัดเรียงให้อยู่ด้านบน
            children: [
              SizedBox(height: 50), // ลดระยะห่างจากด้านบนสุด
              Text(
                'Welcome!',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8), // ลดระยะห่างระหว่างองค์ประกอบ
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
              SizedBox(height: 30), // ลดขนาดของระยะห่างเพิ่มเติม
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
              SizedBox(height: 15), // ลดระยะห่างเพิ่มเติม
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
              SizedBox(height: 50), // ลดขนาดของช่องว่าง
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  elevation: 5,
                  shadowColor: Colors.black.withOpacity(0.3),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    bool network = await _checkNetwork();
                    if (network) {
                      setState(() {
                        _isLoading = true;
                      });
                      await _signIn();
                      setState(() {
                        _isLoading = false;
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No internet connection')),
                      );
                    }
                  }
                },
                child: _isLoading
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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