import 'package:flutter/material.dart';
import 'package:monitoringsystem/check_login.dart';
import 'package:monitoringsystem/user.dart';
import 'package:monitoringsystem/home.dart';

class set_ting extends StatefulWidget{
  const set_ting({Key? key}) : super(key: key);

  @override
  State<set_ting> createState() => _set_tingState();
}
class _set_tingState extends State<set_ting>{
  var _selectedIndex;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  Future logout() async{
    await User.setsigin(false);
    Navigator.pushNamed(context, 'login');
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text("Homepage Flutter Login-php"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          // ignore: prefer_const_literals_to_create_immutables
          children: [
            Text(
              "Welcome To Flutter Homepage",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(
              height: 20,
            ),
            SizedBox(
              width: 250,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    primary: const Color(0xFF3F60A0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: () {
                  logout();
                },
                child: Text("Sign out"),
              ),
            ),
          ],
        ),
      ),
    
      
    );
  }
}