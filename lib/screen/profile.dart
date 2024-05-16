import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:http/http.dart' as http;
import 'package:monitoringsystem/main.dart';

import '../Service/fetch_user_profile.dart';
import 'package:monitoringsystem/user.dart';

class pro_file extends StatefulWidget {
  final String email;

  const pro_file({Key? key, required this.email}) : super(key: key);

  @override
  _pro_fileState createState() => _pro_fileState();
}

class _pro_fileState extends State<pro_file> {
  @override
  void initState() {
    super.initState();
    // เรียกใช้งานฟังก์ชัน fetchUserProfile() เมื่อหน้า Profile ถูกโหลด
    fetchUserProfile(User.email);
  }


  Future logout() async {
    await User.setsigin(false);
    await User.setEmail('');
    FlutterBackgroundService().invoke('stopService');
    Navigator.pushNamed(context, 'login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: ListTile(
                title: Text(
                  'First Name',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(User.firstName),
              ),
            ),
            Divider(),
            Card(
              elevation: 4,
              child: ListTile(
                title: Text(
                  'Last Name',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(User.lastName),
              ),
            ),
            Divider(),
            Card(
              elevation: 4,
              child: ListTile(
                title: Text(
                  'Email',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(User.email),
              ),
            ),
            Divider(),
            Card(
              elevation: 4,
              child: ListTile(
                title: Text(
                  'Phone',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(User.phone),
              ),
            ),
            Divider(),
            Card(
              elevation: 4,
              child: ListTile(
                title: Text(
                  'Description',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(User.description),
              ),
            ),
            Divider(),
            const SizedBox(height: 16),
            const Divider(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  logout();
                  // เรียกเหตุการณ์ stopService

                },
                child: Text('Sing Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
