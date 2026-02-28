import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/state/auth_controller.dart';
import '../../features/chat/chat_conversations_page.dart';
import '../../features/donor/donor_dashboard.dart';
import '../../features/requests/requests_page.dart';
import '../../features/seeker/seeker_dashboard.dart';
import '../../models/user_dto.dart';

class MainShell extends ConsumerStatefulWidget {
  final UserDto user;

  const MainShell({super.key, required this.user});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDonor = widget.user.role == 'donor';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navSurface = isDark
        ? const Color(0xFF111827).withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.92);
    final navText = isDark ? Colors.white : const Color(0xFF374151);

    final pages = [
      isDonor
          ? DonorDashboard(user: widget.user)
          : SeekerDashboard(user: widget.user),
      RequestsPage(user: widget.user),
      ChatConversationsPage(user: widget.user),
      _ProfilePage(user: widget.user),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: KeyedSubtree(
          key: ValueKey<int>(currentIndex),
          child: pages[currentIndex],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            decoration: BoxDecoration(
              color: navSurface,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                ),
              ],
            ),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    );
                  }
                  return TextStyle(color: navText, fontWeight: FontWeight.w500);
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return IconThemeData(color: Theme.of(context).colorScheme.primary);
                  }
                  return IconThemeData(color: navText);
                }),
              ),
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                indicatorColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.2),
                selectedIndex: currentIndex,
                onDestinationSelected: (index) {
                  setState(() => currentIndex = index);
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.inbox_outlined),
                    selectedIcon: Icon(Icons.inbox),
                    label: 'Requests',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.chat_bubble_outline),
                    selectedIcon: Icon(Icons.chat_bubble),
                    label: 'Chat',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfilePage extends ConsumerWidget {
  final UserDto user;

  const _ProfilePage({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                title: Text(user.name),
                subtitle: Text(user.email),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                title: const Text('Role'),
                subtitle: Text(user.role),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
