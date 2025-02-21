import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final url = 'http://127.0.0.1:5000'; // Replace with your HTML page URL
            if (await canLaunch(url)) {
              await launch(url);
            } else {
              throw 'Could not launch $url';
            }
          },
          child: const Text('Open Dashboard'),
        ),
      ),
    );
  }
}
