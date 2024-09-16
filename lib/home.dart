import 'package:flutter/material.dart';
import 'package:Monitoring/screen/history.dart';
import 'package:Monitoring/screen/notifi.dart';
import 'package:Monitoring/screen/profile.dart';
import 'package:Monitoring/screen/settings.dart';
import 'user.dart';

class homepage extends StatefulWidget {
  const homepage({Key? key}) : super(key: key);

  @override
  State<homepage> createState() => _homepageState();
}

class _homepageState extends State<homepage> {
  int _selectedIndex =0;
  Future logout() async{
    await User.setsigin(false);
    Navigator.pushNamed(context, 'login');
  }

   void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  Widget build(BuildContext context) {
    final tabs = [
      noti_fi(),
      his_tory(),
      pro_file(email: '',),
      set_ting(),
    ];

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: tabs[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',

          ),
        ],
      ),
      
  
    );
  }
}
