
import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:monitoringsystem/Service/local_notifcation.dart';
import 'package:monitoringsystem/check_login.dart';
import 'package:monitoringsystem/user.dart';
import 'package:monitoringsystem/login.dart';




Future<void> checkAndSendLineNotification() async {
  var url = Uri.parse('http://192.168.1.104:3001/pushNotification/notify');

  try {
    var response = await http.get(url);
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body) as Map<String, dynamic>;
      print('Response Data: $responseData');

      // ตรวจสอบคีย์ 'data' และข้อมูลที่ได้รับ
      if (responseData.containsKey('message') && responseData.containsKey('notificationStatus')) {
        var message = responseData['message'];
        var notificationStatus = responseData['notificationStatus'];

        if (notificationStatus == "Notification sent successfully!") {
          print("พบการโจมตี");

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
      print('Failed to send notification. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error sending notification: $e');
  }
}