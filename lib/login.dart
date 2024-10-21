import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:cloud_functions/cloud_functions.dart";
import "confirm.dart";
// import "home.dart";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _studentCodeController = TextEditingController();
  final HttpsCallable callableGetSigninCodeViaEmailCloudFunction =
      FirebaseFunctions.instance.httpsCallable("get_signin_code_via_email");
  bool _isLoading = false;

  Future<dynamic> _getSigninCodeViaEmail(String email) async {
    try {
      final result = await callableGetSigninCodeViaEmailCloudFunction
          .call(<String, dynamic>{"email": email});
      _showErrorMessage(result.data);
      print(result.data);
      return result.data;
    } catch (err) {
      print(err);
      // _showErrorMessage("Error: $err");
    }
  }

  void _login() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final studentCode = 'SPI${_studentCodeController.text}';
      if (studentCode.length != 9) {
        _showErrorMessage("Please enter a valid student code");
        return;
      }
      final studentEmail = "$studentCode@stud.spi.nsw.edu.au";
      final result = await _getSigninCodeViaEmail(studentEmail);
      if (result == "ok" && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmPage(
              email: studentEmail,
            ),
          ),
        );
      }
    } catch (err) {
      _showErrorMessage("Error: $err");
    } finally {
      setState(() {
        _isLoading = false;
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
                // disable and opacity 80% and disappear cursor below text field when isLoading is true
                TextField(
                  controller: _studentCodeController,
                  decoration: const InputDecoration(
                    // border: OutlineInputBorder(),
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
                // replace below button to show loading icon when isLoading is true
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text("Login"),
                  ),
              ])),
    );
  }
}
