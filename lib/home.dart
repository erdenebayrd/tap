import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';

class HomePage extends StatelessWidget {
  final String studentEmail;
  const HomePage({super.key, required this.studentEmail});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome, $studentEmail"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: Center(
        child: Text(
          "Welcome to the Home Page, $studentEmail",
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
