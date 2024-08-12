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

  Future<void> updateUserProfile(String field, String value) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.102/flutter_login/UpdataUser.php'),
      body: {
        'email': User.email,
        'field': field,
        'value': value,
      },
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      if (responseBody['status'] == 'success') {
        setState(() {
          switch (field) {
            case 'firstname':
              User.firstName = value;
              break;
            case 'lastname':
              User.lastName = value;
              break;
            case 'phone':
              User.phone = value;
              break;
            case 'description':
              User.description = value;
              break;
          }
        });
      } else {
        // Handle error
        log('Error updating profile: ${responseBody['message']}');
      }
    } else {
      // Handle error
      log('Error updating profile: ${response.statusCode}');
    }
  }

  Future<void> _showEditDialog(String field, String currentValue) async {
    TextEditingController controller =
        TextEditingController(text: currentValue);
    bool isValid = true;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $field'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: field,
              errorText: isValid ? null : 'This field cannot be empty',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  isValid = controller.text.isNotEmpty;
                });
                if (isValid) {
                  Navigator.pop(context);
                  updateUserProfile(field, controller.text);
                }
              },
              child: Text('Save'),
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
        title: Text('User Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'First Name',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () =>
                            _showEditDialog('firstname', User.firstName),
                      ),
                    ],
                  ),
                  subtitle: Text(User.firstName),
                ),
              ),
              Divider(),
              Card(
                elevation: 4,
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Last Name',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () =>
                            _showEditDialog('lastname', User.lastName),
                      ),
                    ],
                  ),
                  subtitle: Text(User.lastName),
                ),
              ),
              Divider(),
              Card(
                elevation: 4,
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Email',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      // No edit button for email
                    ],
                  ),
                  subtitle: Text(User.email),
                ),
              ),
              Divider(),
              Card(
                elevation: 4,
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Phone',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showEditDialog('phone', User.phone),
                      ),
                    ],
                  ),
                  subtitle: Text(User.phone),
                ),
              ),
              Divider(),
              Card(
                elevation: 4,
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Description',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () =>
                            _showEditDialog('description', User.description),
                      ),
                    ],
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    logout();
                    // เรียกเหตุการณ์ stopService
                  },
                  child: Text('Sign Out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
