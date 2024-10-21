import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "home.dart";

class ConfirmPage extends StatefulWidget {
  final String email;

  const ConfirmPage({super.key, required this.email});

  @override
  _ConfirmPageState createState() => _ConfirmPageState();
}

class _ConfirmPageState extends State<ConfirmPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false; // Add loading state
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 6; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          _controllers[i].selection = TextSelection(
              baseOffset: 0, extentOffset: _controllers[i].text.length);
        }
      });
    }
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
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(int index) {
    if (_controllers[index].text.length == 1) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyOtp();
      }
    }
  }

  Future<void> _verifyOtp() async {
    try {
      setState(() {
        _isLoading = true; // Set loading state to true
      });

      String otp = _controllers.map((controller) => controller.text).join();
      print('Verifying OTP: $otp');
      print("Email is: ${widget.email}");
      try {
        final credential = await _auth.signInWithEmailAndPassword(
            email: widget.email, password: otp);
        print(credential.user);
        if (credential.user != null) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(studentEmail: widget.email),
              ),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          _showErrorMessage("No user found for that email.");
          print("No user found for that email.");
        } else if (e.code == 'wrong-password') {
          _showErrorMessage("Wrong OTP provided for that user.");
          print("Wrong password provided for that user.");
        } else {
          _showErrorMessage("Error: $e");
          print("Error: $e");
        }
      }
    } catch (err) {
      print("Error: $err");
    } finally {
      setState(() {
        _isLoading = false; // Set loading state to false after verification
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm OTP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                6,
                (index) => SizedBox(
                  width: 40,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    decoration: const InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => _onOtpChanged(index),
                    enabled: !_isLoading, // Disable input when loading
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading // Show loading indicator or button
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    child: const Text('Verify OTP'),
                  ),
          ],
        ),
      ),
    );
  }
}
