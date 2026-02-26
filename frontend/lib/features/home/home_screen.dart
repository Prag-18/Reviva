import 'package:flutter/material.dart';
import '../donor/donor_dashboard.dart';
import '../seeker/seeker_dashboard.dart';


class HomeScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    if (user["role"] == "donor") {
      return DonorDashboard(user: user);
    } else {
      return SeekerDashboard(user: user);
    }
  }
}

class _HomeScreenState extends State<HomeScreen> {
  String? userName;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final api = ApiService();
    final response = await api.getMe();

    setState(() {
      userName = response.data["name"];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
      ),
      body: Center(
        child: userName == null
            ? const CircularProgressIndicator()
            : Text(
                "Welcome, $userName 🚀",
                style: const TextStyle(fontSize: 24),
              ),
      ),
    );
  }
}
