import 'dart:convert';


import 'package:flutter/material.dart';
import 'package:monitoringsystem/check_login.dart';
import 'package:monitoringsystem/home.dart';
import 'package:monitoringsystem/user.dart';
import 'package:http/http.dart' as http;

class noti_fi extends StatefulWidget {
  const noti_fi({Key? key}) : super(key: key);

  @override
  State<noti_fi> createState() => _noti_fiState();
}

class _noti_fiState extends State<noti_fi> with TickerProviderStateMixin {
  late List<dynamic> warning;
  late List<dynamic> filteredWarning = [];
  late TabController _tabController;
  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(); // Initialize _dateController here
    _tabController = TabController(length: 4, vsync: this);
    getAllWarning().then((_) {
      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          filterWarnings();
        }
      });
    });
  }

  Future<void> getAllWarning([String? formattedDate]) async {
    var url = Uri.parse("http://172.20.10.4/flutter_login/getDectec.php");
    if (formattedDate != null) {
      url = Uri.parse("http://172.20.10.4/flutter_login/getDectec.php?date=$formattedDate");
    }
    var response = await http.get(url);
    if (response.statusCode == 200) {
      setState(() {
        warning = json.decode(response.body)['DetecPattern'];
        filteredWarning = List.from(warning);
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> deleteNotification(String dateDetec) async {
    var response = await http.post(
      Uri.parse("http://172.20.10.4/flutter_login/delete_notification.php"),
      body: jsonEncode({'Date_detec': dateDetec}),
    );
    if (response.statusCode == 200) {
      setState(() {
        filteredWarning.removeWhere((warning) => warning['Date_detec'] == dateDetec);
      });
    } else {
      throw Exception('Failed to delete notification');
    }
  }

   Future<void> _showDatePicker(BuildContext context) async {
    if (_dateController != null) { // ตรวจสอบว่า _dateController ไม่เป็น null ก่อนใช้งาน
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2010),
        lastDate: DateTime.now(),
      );

      if (pickedDate != null && mounted) {
        setState(() {
          _dateController.text = _formattedDate(pickedDate);
          getAllWarning(_formattedDate(pickedDate));
        });
      }
    } else {
      // Handle the case when _dateController is null
      print('_dateController is null');
    }
  }


  String _formattedDate(DateTime date) {
    return "${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}";
  }

  String _twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

void filterWarnings() {
  setState(() {
    switch (_tabController.index) {
      case 0:
        filteredWarning = warning;
        break;
      case 1:
        filteredWarning = warning.where((warning) => warning['Status'] == 'GREEN' && warning['Date_detec'] == _dateController.text).toList();
        break;
      case 2:
        filteredWarning = warning.where((warning) => warning['Status'] == 'ORANGE' && warning['Date_detec'] == _dateController.text).toList();
        break;
      case 3:
        filteredWarning = warning.where((warning) => warning['Status'] == 'RED' && warning['Date_detec'] == _dateController.text).toList();
        break;
    }
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () async {
              await _showDatePicker(context);
            },
            icon: Icon(Icons.calendar_today),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All'),
            Tab(text: 'Green'),
            Tab(text: 'Orange'),
            Tab(text: 'Red'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildWarningList(filteredWarning),
          buildWarningList(filteredWarning),
          buildWarningList(filteredWarning),
          buildWarningList(filteredWarning),
        ],
        
      ),
    );
  }

Widget buildWarningList(List<dynamic> warnings) {
  if (warnings.isEmpty) {
    // ถ้าไม่มีข้อมูลใน warnings
    return Center(
      child: Text(
        'No History ${getStatusText(_tabController.index)} found',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  return ListView.builder(
    itemCount: warnings.length,
    itemBuilder: (context, index) {
      return Card(
        elevation: 3,
        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: ListTile(
          leading: Icon(
            getIconForStatus(warnings[index]['Status']),
            color: getColorForStatus(warnings[index]['Status']),
            size: 32,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Patterns: ${warnings[index]['Patterns']}",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text("Count: ${warnings[index]['Count']}"),
              Text("Status: ${warnings[index]['Status']}"),
              Text("Date Detected: ${warnings[index]['Date_detec']}"),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Confirm Deletion'),
                  content: Text('Are you sure you want to delete this History?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        deleteNotification(warnings[index]['Date_detec']);
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

String getStatusText(int index) {
  switch (index) {
    case 1:
      return 'GREEN';
    case 2:
      return 'ORANGE';
    case 3:
      return 'RED';
    default:
      return '';
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
}
