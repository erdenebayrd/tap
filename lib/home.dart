import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'dart:io' show Platform;
import 'login.dart';
import 'nfc_success_animation.dart';

class HomePage extends StatefulWidget {
  final String studentEmail;
  const HomePage({super.key, required this.studentEmail});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showSuccessAnimation = false;

  Future<void> _signOut(BuildContext context) async {
    final bool confirm = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Sign Out'),
              content: const Text(
                'Are you sure you want to sign out? if you sign out you can NOT login within 12 hours of signing out.',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text('Sign Out'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirm) {
      try {
        // Update lastSignInTime before signing out
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          String currentTime = DateTime.now().toUtc().toIso8601String();
          await user.updateDisplayName(currentTime);
          print("Last sign-in time updated successfully");
        }

        // Sign out the user
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PopScope(
                canPop: false,
                child: LoginPage(),
              ),
            ),
          );
        }
        print("Signed out successfully");
      } catch (e) {
        print("Error updating last sign-in time: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error signing out: $e')),
          );
        }
      }
    }
  }

  Future<void> _readNfc(BuildContext context) async {
    bool isAvailable = await NfcManager.instance.isAvailable();

    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC is not available on this device')),
      );
      return;
    }

    if (Platform.isIOS) {
      _readNfcIOS(context);
    } else if (Platform.isAndroid) {
      _readNfcAndroid(context);
    }
  }

  Future<void> _readNfcIOS(BuildContext context) async {
    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          await _processTag(tag, context);
          NfcManager.instance.stopSession(
            alertMessage: 'NFC tag read successfully!',
            errorMessage: 'Failed to read NFC tag.',
          );
        },
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        alertMessage: 'Hold your iPhone near an NFC tag',
      );
    } catch (e) {
      print('Error starting NFC session: $e');
    }
  }

  Future<void> _readNfcAndroid(BuildContext context) async {
    // Show a custom dialog for Android to mimic iOS UI
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ready to Scan'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.nfc, size: 50),
              SizedBox(height: 16),
              Text('Hold your device near an NFC tag'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                NfcManager.instance.stopSession();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _processTag(NfcTag tag, BuildContext context) async {
    String tagInfo = '';
    print(tag.data);
    if (tag.data['ndef'] != null) {
      var ndefMessage = tag.data['ndef']['cachedMessage'];
      if (ndefMessage != null) {
        for (var record in ndefMessage['records']) {
          tagInfo += 'Type: ${record['type']}\n';
          tagInfo += 'Payload: ${String.fromCharCodes(record['payload'])}\n\n';
        }
      }
    } else {
      tagInfo =
          'Tag ID: ${tag.data['nfca']['identifier'].map((e) => e.toRadixString(16).padLeft(2, '0')).join(':')}';
    }
    print("tagInfo $tagInfo");

    // // Show success animation
    // setState(() {
    //   _showSuccessAnimation = true;
    // });

    // // Wait for the animation to complete
    // await Future.delayed(const Duration(milliseconds: 1500));

    // setState(() {
    //   _showSuccessAnimation = false;
    // });

    // // Show tag info after a short delay
    // await Future.delayed(const Duration(milliseconds: 500));
    // if (mounted) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('NFC Tag Info:\n$tagInfo')),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome, ${widget.studentEmail}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Welcome to the Home Page, ${widget.studentEmail}",
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _readNfc(context),
                  child: const Text('TAP'),
                ),
              ],
            ),
          ),
          if (_showSuccessAnimation)
            NfcSuccessAnimation(
              onAnimationComplete: () {
                setState(() {
                  _showSuccessAnimation = false;
                });
              },
            ),
        ],
      ),
    );
  }
}
