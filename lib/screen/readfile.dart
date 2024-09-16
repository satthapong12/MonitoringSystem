import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

import '../Service/fetch_user_profile.dart';
import '../user.dart';

class FileContentPage extends StatefulWidget {
  final String filePath;

  const FileContentPage({Key? key, required this.filePath}) : super(key: key);

  @override
  _FileContentPageState createState() => _FileContentPageState();
}

class _FileContentPageState extends State<FileContentPage> {
  String fileContent = '';
  bool isLoading = true;
  bool isError = false;
  List<List<Widget>> pages = [];

  @override
  void initState() {
    super.initState();
    fetchUserProfile();

    if (widget.filePath.isNotEmpty) {
      _fetchFileContent();
    } else {
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _fetchFileContent() async {
       Map<String, String?> settings = await User.getSettings();
  String? ip = settings['ip'];
  String? port = settings['port'];
  if (ip == null || ip.isEmpty || port == null || port.isEmpty) {
    ScaffoldMessenger.of(context as BuildContext).showSnackBar(
      SnackBar(content: Text('Please set IP and Port before signing in')),
    );
    return;
  }
    final encodedFilePath = Uri.encodeComponent(widget.filePath);
    var url = Uri.parse(
        "http://$ip:$port/readfile/file-content/$encodedFilePath");

    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          fileContent = response.body;
          isLoading = false;
          pages = _parseFileContent(fileContent);
        });
      } else {
        setState(() {
          isError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  Color getRandomColor() {
    Random random = Random();
    Color randomColor;

    do {
      randomColor = Color.fromRGBO(
        random.nextInt(256), // สุ่มค่า R
        random.nextInt(256), // สุ่มค่า G
        random.nextInt(256), // สุ่มค่า B
        1, // ค่า opacity เป็น 1 หรือ 100% ความทึบแสง
      );
    } while (randomColor == Colors.black || randomColor == Colors.white);

    return randomColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File Content'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : isError
              ? Center(child: Text('Failed to load file content.'))
              : PageView.builder(
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: pages[index],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  List<List<Widget>> _parseFileContent(String content) {
    List<String> lines = content.split('\n');
    List<List<Widget>> pages = [];
    List<Widget> currentPageWidgets = [];
    String? currentDate;
    int number = 1;
    for (var line in lines) {
      if (RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$').hasMatch(line)) {  // ตรวจสอบบรรทัดที่เป็นวันที่และเวลา
    //if (currentPageWidgets.isNotEmpty) {
      //pages.add(currentPageWidgets);
      //currentPageWidgets = [];
    //}
    currentDate = line;  // ใช้บรรทัดนี้เป็นวันที่
    currentPageWidgets.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Date: $currentDate',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  } else if (line.startsWith('Type :')) {
        Color randomColor = getRandomColor(); // เรียกฟังก์ชันสุ่มสี

        currentPageWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              'Type ${line.substring(5).trim()}',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: randomColor),
            ),
          ),
        );
      } else if (line.startsWith('Pattern :')) {
        currentPageWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              'Pattern ${line.substring(8).trim()}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        );
      } else if (line.isNotEmpty) {
        currentPageWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              line,
              style: TextStyle(fontSize: 14),
            ),
          ),
        );
      }
    }

    if (currentPageWidgets.isNotEmpty) {
      pages.add(currentPageWidgets);
    }

    return pages;
  }
}
