import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final HttpsCallable callableVerifyOtpCloudFunction =
      FirebaseFunctions.instance.httpsCallable("verify_otp");
  bool _isLoading = false; // Add loading state

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
      // TODO: Implement OTP verification logic
      print('Verifying OTP: $otp');
      print("Email is: ${widget.email}");

      // Simulate a network call for OTP verification
      // await Future.delayed(const Duration(seconds: 2));

      // Here you would typically call your backend to verify the OTP
      // For example:
      // final response = await verifyOtpWithBackend(otp);
      final response =
          await callableVerifyOtpCloudFunction.call(<String, dynamic>{
        "email": widget.email,
        "otp": otp,
      });
      print(response.data);
    } catch (err) {
      print("Error: $err");
    } finally {
      setState(() {
        _isLoading = false; // Set loading state to false after verification
      });
    }

    // Handle the response accordingly
    // if (response.success) {
    //   // Navigate to the next page
    // } else {
    //   // Show error message
    // }
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
