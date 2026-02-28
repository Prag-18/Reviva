import 'package:flutter/material.dart';

import '../../models/user_dto.dart';

class DonorDashboard extends StatelessWidget {
  final UserDto user;

  const DonorDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donor Dashboard')),
      body: Center(
        child: Text(
          'Welcome donor ${user.name}',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
