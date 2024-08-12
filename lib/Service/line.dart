
import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:monitoringsystem/Service/local_notifcation.dart';
import 'package:monitoringsystem/check_login.dart';
import 'package:monitoringsystem/user.dart';
import 'package:monitoringsystem/login.dart';




Future<void> checkAndSendLineNotification() async {

  
 
     var url = Uri.parse('http://192.168.1.102/flutter_login/pushNotification.php');
  try {
    var response = await http.get(url);
    print(response.statusCode);
    if (response.statusCode == 200) {
      var responseData = json.decode(response.body) as Map<String, dynamic>;
      var data = responseData['data'];
      var message = data['message'];
      if(message == null){
          print("no Data");
      }
      var notificationStatus = data['notificationStatus'];

    if(notificationStatus == "Notification sent successfully!"){
      print("พบการโจมตี");
        if (message != null) {
        var lines = message.split('\n');
        var title = lines[0];
        var body = '';
        var payload = '';

        for (var i = 1; i < lines.length; i++) {
          body += lines[i] + '\n';
        }

        LocalNotifications.showSimple(
          title: title,
          body: body,
          payload: payload,
        );
      } else {
        // แสดงข้อความหรือกระทำตามที่คุณต้องการในกรณีที่ข้อความเป็น null
        print('Message is null. Cannot process notification.');
      }
    }else {
       // print('ไม่พบการโจมตีใหม่');
      }
    } else {
      print('Failed to send notification. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error sending notification: $e');
  }
  
}
