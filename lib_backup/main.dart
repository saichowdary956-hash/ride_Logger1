import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Ride Data Logger')),
        body: Center(
          child: Text('App is working!', style: TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}
