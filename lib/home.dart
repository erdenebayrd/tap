import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final String studentCode;
  const HomePage({super.key, required this.studentCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome, $studentCode"),
      ),
      body: Center(
        child: Text("Welcome to the Home Page, $studentCode",
            style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}
