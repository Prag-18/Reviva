import 'package:flutter/material.dart';

class DonorDashboard extends StatelessWidget {
  final Map<String, dynamic> user;

  const DonorDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Donor Dashboard"),
      ),
      body: Center(
        child: Text(
          "Welcome Donor ${user["name"]} 🩸",
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}