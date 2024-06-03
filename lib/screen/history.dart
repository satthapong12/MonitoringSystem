import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class his_tory extends StatefulWidget {
  const his_tory({Key? key}) : super(key: key);

  @override
  _his_toryState createState() => _his_toryState();
}

class _his_toryState extends State<his_tory> {
  late Future<List<Map<String, dynamic>>> _notificationFuture;
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _notificationFuture = fetchNotifications("");
    _dateController = TextEditingController();
  }

  Future<List<Map<String, dynamic>>> fetchNotifications(String date) async {
    final response = await http.get(
        Uri.parse('http://192.168.1.100/flutter_login/show_notification.php?date=$date'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      List<Map<String, dynamic>> notifications =
          data.map((e) => e as Map<String, dynamic>).toList();

      // Filter notifications to only include those with the selected date
      notifications = notifications.where((notification) =>
          notification['Date_detec'].startsWith(date)).toList();

      return notifications;
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  IconData getIconForStatus(String status) {
    switch (status) {
      case 'GREEN':
        return Icons.check_circle;
      case 'ORANGE':
        return Icons.error_outline;
      default:
        return Icons.error;
    }
  }

  Color getColorForStatus(String status) {
    switch (status) {
      case 'GREEN':
        return Colors.green;
      case 'ORANGE':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Notification"),
            IconButton(
              onPressed: () async {
                await _showDatePicker(context);
              },
              icon: Icon(Icons.calendar_today),
            ),
          ],
        ),
      ),
      body: Center(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _notificationFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              if (snapshot.data!.isEmpty) {
                return Text('No notifications found.');
              } else {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var notification = snapshot.data![index];
                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: Icon(
                          getIconForStatus(notification['Status']),
                          color: getColorForStatus(notification['Status']),
                          size: 32,
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Patterns: ${notification['Patterns']}",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text("Count: ${notification['Count']}"),
                            Text("Status: ${notification['Status']}"),
                            Text("Date Detected: ${notification['Date_detec']}"),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            showDialog(
                              context: context,
                               builder: (context) => AlertDialog(
                                 title: Text('Confirm Deletion'),
                                 content: Text('Are you sure you want to delete this Notification?'),
                                 actions: [
                                   TextButton(
                                     onPressed:(){
                                        Navigator.of(context).pop();
                                     },
                                     child: Text('Cancle'),
                                   ),
                                   TextButton(
                                     onPressed: (){
                                     Navigator.of(context).pop();
                                     _deleteNotification(notification);

                                     },
                                     child: Text('Delete'),
                                     ),
                                   ],
                               ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _deleteNotification(Map<String, dynamic> notification) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.100/flutter_login/delete_notification.php'),
      body: jsonEncode(notification),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      // Reload notifications after deletion
      setState(() {
        _notificationFuture = fetchNotifications("");
      });
    } else {
      throw Exception('Failed to delete notification');
    }
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && mounted) {
      setState(() {
        _dateController.text = _formattedDate(pickedDate);
        _notificationFuture = fetchNotifications(_formattedDate(pickedDate));
      });
    }
  }

  String _formattedDate(DateTime date) {
    return "${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}";
  }

  String _twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }
}
