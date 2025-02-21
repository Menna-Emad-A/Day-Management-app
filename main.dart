import 'package:flutter/material.dart';
import 'login_pages/user_sign_page.dart';
import 'login_pages/user_login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: user_login_page(),
  ));
}