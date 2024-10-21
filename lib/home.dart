import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'dart:io' show Platform;
import 'login.dart';

class HomePage extends StatefulWidget {
  final String studentEmail;
  const HomePage({super.key, required this.studentEmail});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _tapHistory = [];

  @override
  void initState() {
    super.initState();
    _loadTapHistory();
  }

  Future<void> _loadTapHistory() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('taps')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      setState(() {
        _tapHistory = querySnapshot.docs
            .map((doc) => {
                  'tagId': doc['tagId'],
                  'timestamp': (doc['timestamp'] as Timestamp).toDate(),
                })
            .toList();
      });
    }
  }

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
          await NfcManager.instance.stopSession();
        },
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        alertMessage: 'Hold your iPhone near a tag',
      );
    } catch (e) {
      print('Error starting NFC session: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reading NFC: $e')),
      );
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
              Text('Hold your device near a tag'),
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
    print(tag.data);

    String uniqueId = '';
    if (tag.data['mifare'] != null &&
        tag.data['mifare']['identifier'] != null) {
      List<int> identifier = tag.data['mifare']['identifier'];
      uniqueId =
          identifier.map((e) => e.toRadixString(16).padLeft(2, '0')).join(':');
    }

    print("Unique ID: $uniqueId");

    // Get the current user
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && uniqueId.isNotEmpty) {
      // Add the tap data to Firestore
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .collection('taps')
            .add(
          {
            'tagId': uniqueId,
            'timestamp': FieldValue.serverTimestamp(),
          },
        );
        print("Tag data added to Firestore successfully");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NFC tag data saved successfully')),
        );
      } catch (e) {
        print("Error adding tag data to Firestore: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving NFC tag data: $e')),
        );
      }
    }

    // After successfully adding the tag data to Firestore
    await _loadTapHistory(); // Reload the tap history
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
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _tapHistory.length,
              itemBuilder: (context, index) {
                final tap = _tapHistory[index];
                return ListTile(
                  title: Text('Tag ID: ${tap['tagId']}'),
                  subtitle: Text('Tapped on: ${tap['timestamp'].toString()}'),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _readNfc(context),
        label: const Text('TAP'),
        icon: const Icon(Icons.nfc),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
