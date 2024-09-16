

import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:Monitoring/Service/local_notifcation.dart';
import 'package:Monitoring/check_login.dart';
import 'package:Monitoring/user.dart';
import 'package:Monitoring/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<String>> sendtocheckAnd() async {
  // รับโทเค็นจาก User
    Map<String, String?> settings = await User.getSettings();
  String? ip = settings['ip'];
  String? port = settings['port'];
  
  List<String> storedTokens = await User.getLineNotifyTokens();
  print('check update tokens fun: $storedTokens'); // Debugging line
  
  var url = Uri.parse('http://$ip:$port/pushNotification/receiveTokens');

  try {
    var response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'tokens': storedTokens}),
    );

    if (response.statusCode == 200) {
      print('Tokens successfully sent to the server.');
    } else {
      print('Failed to send tokens. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error sending tokens: $e');
  }

  return storedTokens; // ส่งคืนโทเค็น
}



Future<void> checkAndSendLineNotification() async {
  Map<String, String?> settings = await User.getSettings();
  String? ip = settings['ip'];
  String? port = settings['port'];
 
  var url = Uri.parse('http://$ip:$port/pushNotification/sendNotifications');

  try {
    // รับข้อมูลจากเซิร์ฟเวอร์โดยไม่ส่งโทเค็น
    var response = await http.post(url, headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    });

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body) as Map<String, dynamic>;

      if (responseData.containsKey('message') && responseData.containsKey('notificationStatus')) {
        var message = responseData['message'];
        var notificationStatus = responseData['notificationStatus'];

        if (notificationStatus == "Notification sent successfully!") {
          print("Notification sent successfully.");

          if (message != null) {
            var lines = message.split('\n');
            var title = lines.isNotEmpty ? lines[0] : 'Notification';
            var body = lines.skip(1).join('\n');
            var payload = '';

            LocalNotifications.showSimple(
              title: title,
              body: body,
              payload: payload,
            );
          } else {
            print('Message is null. Cannot process notification.');
          }
        } else {
          print('No new attacks found.');
        }
      } else {
        print('Invalid response format or data is null.');
      }
    } else {
      print('Failed to receive notification. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error receiving notification: $e');
  }
}
