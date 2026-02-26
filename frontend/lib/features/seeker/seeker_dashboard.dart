import 'package:flutter/material.dart';

class SeekerDashboard extends StatelessWidget {
  final Map<String, dynamic> user;

  const SeekerDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seeker Dashboard"),
      ),
      body: Center(
        child: Text(
          "Welcome Seeker ${user["name"]} ❤️",
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}