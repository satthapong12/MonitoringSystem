import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:monitoringsystem/Service/local_notifcation.dart';
import 'package:monitoringsystem/check_login.dart';
import 'package:monitoringsystem/user.dart';
import 'package:monitoringsystem/home.dart';
import 'package:http/http.dart' as http;


import '../Service/line.dart';

class his_tory extends StatefulWidget {
  const his_tory({Key? key}) : super(key: key);

  @override
  _his_toryState createState() => _his_toryState();
}

class _his_toryState extends State<his_tory> {
  late Future<List<Map<String, dynamic>>> _notificationFuture;

  @override
  void initState() {
    super.initState();
    _notificationFuture = fetchNotifications();
  }

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final response = await http.get(
        Uri.parse('http://172.20.10.4/flutter_login/show_notification.php'));

    if (response.statusCode == 200) {
      // แปลงข้อมูล JSON ให้กลายเป็น List<Map<String, dynamic>>
      List<dynamic> data = jsonDecode(response.body);
      List<Map<String, dynamic>> notifications =
          data.map((e) => e as Map<String, dynamic>).toList();

      return notifications;
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text("Notification"),
      ),
      body: Center(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _notificationFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              if (snapshot.data!.isEmpty) {
                return Text('No notifications found.');
              } else {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var notification = snapshot.data![index];
                    return Card(
                      child: ListTile(
                        title: Text('Date Detected: ${notification['Date Detected']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pattern: ${notification['Pattern']}'),
                            Text('Count: ${notification['Count']}'),
                            Text('Status: ${notification['Status']}'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            }
          },
        ),
      ),
    );
  }
}