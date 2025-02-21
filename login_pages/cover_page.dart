import 'package:flutter/material.dart';
import 'user_sign_page.dart';

// Splash Screen Widget
class cover_page extends StatefulWidget {
  @override
  _cover_page createState() => _cover_page();
}

class _cover_page extends State<cover_page> {
  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => user_sign_page()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
       decoration: BoxDecoration(
        image: DecorationImage(
        image: AssetImage("assets/images/cover.png"),
        fit: BoxFit.cover,
       ),
       ),

      ),
    );
  }
}



