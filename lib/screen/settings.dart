import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:Monitoring/check_login.dart';
import 'package:Monitoring/user.dart';
import 'package:Monitoring/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../Service/line.dart';
import '../main.dart';

class set_ting extends StatefulWidget {
  const set_ting({Key? key}) : super(key: key);

  @override
  State<set_ting> createState() => _SetTingState();
}

class _SetTingState extends State<set_ting> {
  bool _notificationsEnabled = true;
  List<dynamic> _attackGroups = [];
  Timer? _updateTimer;
  String? _lineNotifyToken;
  List<dynamic> _tokens = [];
  List<String> _selectedEmail = [];
  late Future<bool?> _uroleFuture;
  bool isAdmin = true; // Variable to store the admin status

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
    _fetchAttackGroups();
    _loadEmails();
    _uroleFuture = User.geturole();
    _checkIfAdmin(); // Check admin status
  }

  Future<void> _checkIfAdmin() async {
    bool? role = await User.geturole();
    setState(() {
      isAdmin = role ?? true; // Default to false if not set
    });
  }

  void _startHourlyUpdate() {
    _updateTimer = Timer.periodic(Duration(hours: 1), (timer) {
      // Add logic for periodic updates if needed
    });
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }

  Future<void> updateTokens(List<String> newTokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('lineNotifyTokens', newTokens);
  }

  Future<void> _updateNotificationPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = enabled;
      prefs.setBool('notificationsEnabled', enabled);
    });
  }

  Future<void> _fetchTokens() async {
    Map<String, String?> settings = await User.getSettings();
    String? ip = settings['ip'];
    String? port = settings['port'];
    SharedPreferences prefs = await SharedPreferences.getInstance();
     String? token = prefs.getString('jwt_token');
    final response = await http
        .get(Uri.parse('http://$ip:$port/routes/tokenapi/fetch_tokens'),
        headers: {
          'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        });

    if (response.statusCode == 200) {
      setState(() {
        _tokens = json.decode(response.body)['tokens'];
      });
    } else {
      print('Failed to load tokens');
    }
  }

  Future<void> _fetchAttackGroups() async {
    Map<String, String?> settings = await User.getSettings();
    String? ip = settings['ip'];
    String? port = settings['port'];
      SharedPreferences prefs = await SharedPreferences.getInstance();
     String? token = prefs.getString('jwt_token');
    final response =
        await http.get(Uri.parse('http://$ip:$port/routes/setThreshold/fetch_group'),
         headers: {
          'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        }
        );
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

  Future<void> _showTokenDialog(BuildContext context) async {
    Map<String, String?> settings = await User.getSettings();
    String? ip = settings['ip'];
    String? port = settings['port'];
      SharedPreferences prefs = await SharedPreferences.getInstance();
     String? token = prefs.getString('jwt_token');
    final response =
        await http.get(Uri.parse('http://$ip:$port/routes/tokenapi/fetch_tokens'),
         headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
        );

    if (response.statusCode == 200) {
      final List<dynamic> tokens = json.decode(response.body)['tokens'];

      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                title: const Text('Email with Line Notify Token'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: tokens.length,
                    itemBuilder: (BuildContext context, int index) {
                      final email = tokens[index]['email'] as String;
                      final token = tokens[index]['token'];
                      final isTokenAdded = _selectedEmail.contains(email);

                      return ListTile(
                        title: Text(email),
                        trailing: isTokenAdded
                            ? IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  List<String> savedTokens =
                                      prefs.getStringList('lineNotifyTokens') ??
                                          [];
                                  List<String> savedEmails =
                                      prefs.getStringList('lineNotifyEmails') ??
                                          [];

                                  savedTokens.remove(token);
                                  savedEmails.remove(email);
                                  await prefs.setStringList(
                                      'lineNotifyTokens', savedTokens);
                                  await prefs.setStringList(
                                      'lineNotifyEmails', savedEmails);
                                  deleteToken(token);

                                  setState(() {
                                    _selectedEmail = savedEmails;
                                  });
                                },
                              )
                            : IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () async {
                                  if (!isTokenAdded) {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    List<String> savedTokens =
                                        prefs.getStringList(
                                                'lineNotifyTokens') ??
                                            [];
                                    List<String> savedEmails =
                                        prefs.getStringList(
                                                'lineNotifyEmails') ??
                                            [];

                                    savedTokens.add(token);
                                    savedEmails.add(email);

                                    await prefs.setStringList(
                                        'lineNotifyTokens', savedTokens);
                                    await prefs.setStringList(
                                        'lineNotifyEmails', savedEmails);
                                    sendtocheckAnd();

                                    setState(() {
                                      _selectedEmail = savedEmails;
                                    });
                                  }
                                },
                              ),
                      );
                    },
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Close'),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      List<String> savedTokens =
                          prefs.getStringList('lineNotifyTokens') ?? [];
                      List<String> savedEmails =
                          prefs.getStringList('lineNotifyEmails') ?? [];

                      print('Stored Tokens: $savedTokens');
                      print('Stored Emails: $savedEmails');
                      await _loadEmails();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        },
      );
    } else {
      print('Failed to load tokens');
    }
  }

  Future<void> _loadEmails() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? emails = prefs.getStringList('lineNotifyEmails');
    setState(() {
      _selectedEmail = emails ?? [];
    });
  }

  Future<void> logout() async {
    await User.setsigin(false);
    await User.setEmail('');
    FlutterBackgroundService().invoke('stopService');
    Navigator.pushNamed(context, 'login');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text("Settings"),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () async {
              await logout();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              elevation: 4,
              child: Column(
                children: [
                  ListTile(
                    title: Text("Enable Notifications"),
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (bool value) async {
                        _updateNotificationPreference(value);
                        if (value) {
                          await initializeService();
                          print("Notifications enabled");
                        } else {
                          FlutterBackgroundService().invoke('stopService');
                          print("Notifications disabled");
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attack Groups',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    ..._attackGroups
                        .map((group) => ListTile(
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 8.0),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      group['name'],
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                'Threshold: ${group['Threshold']}',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600]),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () {
                                  _showEditDialog(context, group);
                                },
                              ),
                            ))
                        .toList(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            if (isAdmin) // Only show if the user is an admin
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Line Notify Token',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        _selectedEmail.isNotEmpty
                            ? _selectedEmail.join(', ')
                            : 'No email set',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          _showTokenDialog(context);
                        },
                        child: Text('Manage Notification Line'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
