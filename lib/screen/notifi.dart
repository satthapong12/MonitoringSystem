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
  late List<dynamic> filteredWarning = []; // Initialize filteredWarning
  late TabController _tabController;

  Future<void> getAllWarning() async {
    var response = await http.get(Uri.parse("http://172.20.10.4/flutter_login/getDectec.php"));
    if (response.statusCode == 200) {
      setState(() {
        warning = json.decode(response.body)['DetecPattern'];
        filteredWarning = List.from(warning); // Initially set filteredWarning to all warnings
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  // Define a function to return the icon based on status
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

  // Define a function to return the color based on status
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
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    getAllWarning().then((_) {
      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          filterWarnings();
        }
      });
    });
  }

  void filterWarnings() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          filteredWarning = List.from(warning); // All warnings
          break;
        case 1:
          filteredWarning = warning.where((warning) => warning['Status'] == 'GREEN').toList(); // Green warnings
          break;
        case 2:
          filteredWarning = warning.where((warning) => warning['Status'] == 'ORANGE').toList(); // Orange warnings
          break;
        case 3:
          filteredWarning = warning.where((warning) => warning['Status'] == 'RED').toList(); // Red warnings
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
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
          buildWarningList(filteredWarning), // All warnings
          buildWarningList(filteredWarning), // Green warnings
          buildWarningList(filteredWarning), // Orange warnings
          buildWarningList(filteredWarning), // Red warnings
        ],
      ),
    );
  }

  Widget buildWarningList(List<dynamic> warnings) {
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
          ),
        );
      },
    );
  }
}