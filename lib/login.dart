import "package:flutter/material.dart";
import "package:flutter/services.dart";
// import "package:firebase_auth/firebase_auth.dart";
// import "home.dart";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _studentCodeController = TextEditingController();

  void _login() {
    final studentCode = 'SPI${_studentCodeController.text}';
    if (studentCode.length != 9) {
      _showErrorMessage("Please enter a valid student code");
      return;
    }

    print("Student Code: $studentCode");
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _studentCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login Page"),
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextField(
                  controller: _studentCodeController,
                  decoration: const InputDecoration(
                    labelText: "Student code",
                    prefix: Text("SPI"),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: _login,
                  child: const Text("Login"),
                ),
              ])),
    );
  }
}
