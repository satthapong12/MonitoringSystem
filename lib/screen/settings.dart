import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:monitoringsystem/check_login.dart';
import 'package:monitoringsystem/user.dart';
import 'package:monitoringsystem/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../main.dart';

class set_ting extends StatefulWidget {
  const set_ting({Key? key}) : super(key: key);

  @override
  State<set_ting> createState() => _set_tingState();
}

class _set_tingState extends State<set_ting> {
  bool _notificationsEnabled = true; // ค่าเริ่มต้น
  List<dynamic> _attackGroups = [];
  Timer? _updateTimer; // ใช้เพื่อเก็บ Timer

@override
void dispose(){
  _updateTimer?.cancel(); // ยกเลิก Timer เมื่อ State ถูกทำลาย
  super.dispose();
}

  void _startHourlyUpdate() {
    _updateTimer = Timer.periodic(Duration(hours: 1), (timer) {
      // เรียกฟังก์ชันที่ต้องการอัปเดต threshold
      //_updateThreshold();
    });
  }


  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
    _fetchAttackGroups();
  }

  // โหลดค่าการตั้งค่าการแจ้งเตือนจาก SharedPreferences
  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }

  // อัปเดตการตั้งค่าการแจ้งเตือนใน SharedPreferences
  Future<void> _updateNotificationPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = enabled;
      prefs.setBool('notificationsEnabled', enabled);
    });
  }
  Future<void> _fetchAttackGroups() async {
       Map<String, String?> settings = await User.getSettings();
  String? ip = settings['ip'];
  String? port = settings['port'];
    final response =
        await http.get(Uri.parse('http://$ip:$port/setThreshold/fetch_group'));
    if (response.statusCode == 200) {
      setState(() {
        _attackGroups = json.decode(response.body)['AttackGroup'];
        
      });
    } else {
      print('Failed to load attack groups');
    }
  }

  Future<void> _updateThreshold(int id, String name, double threshold) async {
      Map<String, String?> settings = await User.getSettings();
  String? ip = settings['ip'];
  String? port = settings['port'];
    final response = await http.put(
      Uri.parse('http://$ip:$port/setThreshold/update_threshold/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'name': name,
        'threshold': threshold,
      }),
    );

    if (response.statusCode == 200) {
      print('Threshold updated successfully');
      _fetchAttackGroups();
    } else {
      print('Failed to update threshold');
      print('Response: ${response.body}');
    }
  }

  Future<void> _showEditDialog(BuildContext context, dynamic group) async {
    final TextEditingController _thresholdController =
        TextEditingController(text: group['Threshold'].toString());

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Threshold for ${group['name']}'),
          content: TextField(
            controller: _thresholdController,
            decoration: InputDecoration(
              labelText: 'Threshold',
            ),
            keyboardType: TextInputType.number,
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
              onPressed: () {
                final double newThreshold =
                    double.tryParse(_thresholdController.text) ??
                        group['Threshold'];
                _updateThreshold(group['id'], group['name'], newThreshold);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> logout() async {
    await User.setsigin(false);
    await User.setEmail('');
    FlutterBackgroundService().invoke('stopService');
    Navigator.pushNamed(context, 'login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text("Settings"),
      ),
      body: ListView(
        padding: EdgeInsets.all(8.0),
        children: [
          SwitchListTile(
            title: Text("Enable Notifications"),
            value: _notificationsEnabled,
            onChanged: (bool value) async {
              _updateNotificationPreference(value);
              if (value) {
                await initializeService();
                print("เปิดการแจ้งเตือน");
              } else {
                FlutterBackgroundService().invoke('stopService');
                print("ปิดการแจ้งเตือน");
              }
            },
          ),
          SizedBox(height: 20),
          Text('Attack Groups',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ..._attackGroups
              .map((group) => ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(group['name']),
                        ),
                      ],
                    ),
                    subtitle: Text('Threshold: ${group['Threshold']}'),
                    trailing: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        _showEditDialog(
                            context, group); // เปิด popup เพื่อแก้ไขข้อมูล
                      },
                    ),
                  ))
              .toList(),
          const Divider(),
          SizedBox(
            height: 280,
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                logout();
              },
              child: Text('Sign Out'),
            ),
          ),
        ],
      ),
    );
  }
}
