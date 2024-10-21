import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final String studentEmail;
  const HomePage({super.key, required this.studentEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome, $studentEmail"),
      ),
      body: Center(
        child: Text("Welcome to the Home Page, $studentEmail",
            style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}
