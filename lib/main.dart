import 'dart:async';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:monitoringsystem/Service/local_notifcation.dart';
import 'package:monitoringsystem/home.dart';
import 'package:monitoringsystem/user.dart';
import 'Service/line.dart';
import 'login.dart';
import 'register.dart';
import 'check_login.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotifications.intit();
   //initializeService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: check_login(),
      routes: {
        'register': (context) => register(),
        'home': (context) => homepage(),
        'login': (context) => login(),
      },
    );
  }
}


Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
      iosConfiguration: IosConfiguration(),
      androidConfiguration:
          AndroidConfiguration(onStart: onStart, isForegroundMode: true));
  await service.startService();

  
}


void onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Timer.periodic(const Duration(seconds: 5), (timer) async {
    // Wait for SharedPreferences to update
    //await User.getsignin();
     await checkAndSendLineNotification();
  
  });
}


//@pragma('vm:entry-point')