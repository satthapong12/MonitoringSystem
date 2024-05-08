import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:monitoringsystem/check_login.dart';
import 'package:monitoringsystem/user.dart';
import 'package:monitoringsystem/home.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class pro_file extends StatefulWidget {
  const pro_file({Key? key}) : super(key: key);

  @override
  State<pro_file> createState() => _pro_fileState();
}


class _pro_fileState extends State<pro_file> {

Future<void> fetchUserData() async {
  String url = "http://172.20.10.3/flutter_login/getperson.php";
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    var data = json.decode(response.body);
    print(data); 
    if (data.containsKey("error")) {
      print("Error occurred: ${data["error"]}");
    } else if (data.containsKey("user")) {
      var user = data["user"];
      User.firstName = user['firstname'] ?? "";
      User.lastName = user['lastname'] ?? "";
      User.email = user['email'] ?? "";
      User.phone = user['phone'] ?? "";
      User.description = user['description'] ?? "";

      // Call setState to rebuild the widget with updated data
      setState(() {});
    } else {
      print("Unknown response format");
    }
  } else {
    print("Failed to fetch data: ${response.statusCode}");
  }
}

 @override
void initState() {
  super.initState();
  fetchUserData();
}
 

  Widget userProfile(IconData iconData, String userData) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12), color: Colors.grey),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            iconData,
            size: 30,
            color: Colors.black,
          ),
          const SizedBox(
            width: 16,
          ),
          Text(
            userData,
            style: const TextStyle(
              fontSize: 15,
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: ListView(
          children: <Widget>[
            const SizedBox(
              height: 30,
            ),
            userProfile(Icons.person, User.firstName),
            const SizedBox(
              height: 20,
            ),
            userProfile(Icons.person, User.lastName),
            const SizedBox(
              height: 20,
            ),
            userProfile(Icons.email, User.email),
            const SizedBox(
              height: 20,
            ),
            userProfile(Icons.phone, User.phone),
            const SizedBox(
              height: 20,
            ),
            userProfile(Icons.description, User.description),
          ],
        ),
      ),
    );
  }
}
