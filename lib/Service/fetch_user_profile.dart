import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:monitoringsystem/user.dart';

Future<void> fetchUserProfile(String userEmail) async {
  String url = "http://192.168.1.102/flutter_login/getperson.php";
  final response = await http.get(Uri.parse(url));
  String message = '';
  String item = '';
  if (response.statusCode == 200) {
    var data = json.decode(response.body);
    for (var item in data) {
      message = item['email'];
      if (message == await User.getEmail()) {
        User.firstName = item['firstname'] as String;
        User.lastName = item['lastname'] as String;
        User.email = item['email'] as String;
        User.phone = item['phone'] as String;
        User.description = item['description'] as String;
      } else {
        print("User data not found for email: ${await User.getEmail()}");
      }
      print("email: $message");
    }
  } else {
    print("Failed to fetch data: ${response.statusCode}");
  }
}
