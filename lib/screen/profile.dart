import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:http/http.dart' as http;
import 'package:Monitoring/main.dart';

import '../Service/fetch_user_profile.dart';
import 'package:Monitoring/user.dart';

class pro_file  extends StatefulWidget {
  final String email;

  const pro_file ({Key? key, required this.email}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<pro_file > {
  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    User.checkLoginStatus();
  }

  Future<void> updateUserProfile(String field, String value) async {
    Map<String, String?> settings = await User.getSettings();
    String? ip = settings['ip'];
    String? port = settings['port'];
    final response = await http.post(
      Uri.parse('http://$ip:$port/update_user'),
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
            case 'token':
              User.token = value;
              break;
          }
        });
      } else {
        log('Error updating profile: ${responseBody['message']}');
      }
    } else {
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

  Widget buildProfileCard(String title, String value, String field, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(value),
        trailing: IconButton(
          icon: Icon(Icons.edit, color: Colors.blueAccent),
          onPressed: () => _showEditDialog(field, value),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildProfileCard(
              'First Name',
              User.firstName,
              'firstname',
              Icons.person,
            ),
            buildProfileCard(
              'Last Name',
              User.lastName,
              'lastname',
              Icons.person_outline,
            ),
            buildProfileCard(
              'Phone',
              User.phone,
              'phone',
              Icons.phone,
            ),
            buildProfileCard(
              'Description',
              User.description,
              'description',
              Icons.description,
            ),
            buildProfileCard(
              'TokenLine',
              User.token,
              'token',
              Icons.token,
            ),
            // No edit button for email
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Icon(Icons.email, color: Colors.blueAccent),
                title: Text(
                  'Email',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(User.email),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
