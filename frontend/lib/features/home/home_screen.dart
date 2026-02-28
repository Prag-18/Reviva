import 'package:flutter/material.dart';
import '../../models/user_dto.dart';
import '../../core/layout/main_shell.dart';

class HomeScreen extends StatelessWidget {
  final UserDto user;

  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return MainShell(user: user);
  }
}
