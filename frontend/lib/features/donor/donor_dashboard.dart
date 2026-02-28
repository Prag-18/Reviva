import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/utils/location_service.dart';
import '../../models/chat_conversation_dto.dart';
import '../../models/donation_request_dto.dart';
import '../../models/user_dto.dart';
import '../chat/chat_conversations_page.dart';
import '../requests/requests_page.dart';

class DonorDashboard extends ConsumerStatefulWidget {
  final UserDto user;

  const DonorDashboard({super.key, required this.user});

  @override
  ConsumerState<DonorDashboard> createState() => _DonorDashboardState();
}

class _DonorDashboardState extends ConsumerState<DonorDashboard>
    with WidgetsBindingObserver {
  bool _syncingLocation = false;
  String? _syncError;
  DateTime? _lastSyncedAt;
  Timer? _periodicSyncTimer;
  bool _loadingDashboard = true;
  String? _dashboardError;
  bool _available = false;
  bool _updatingAvailability = false;
  List<DonationRequestDto> _donorRequests = const [];
  List<ChatConversationDto> _conversations = const [];

  @override
  void initState() {
    super.initState();
    _available = widget.user.available;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshDashboard(initialLoad: true));
    _periodicSyncTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => unawaited(_syncLocation(showSnackBarOnError: false)),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodicSyncTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshDashboard(initialLoad: false));
    }
  }

  Future<void> _refreshDashboard({required bool initialLoad}) async {
    if (initialLoad) {
      setState(() {
        _loadingDashboard = true;
        _dashboardError = null;
      });
    }

    await _syncLocation(showSnackBarOnError: false);

    try {
      final results = await Future.wait([
        ref.read(requestRepositoryProvider).fetchMyRequests(widget.user.id),
        ref.read(chatRepositoryProvider).fetchConversations(),
      ]);

      final requests = results[0] as List<DonationRequestDto>;
      final donorRequests = requests
          .where((request) => request.donorId == widget.user.id)
          .toList();
      donorRequests.sort(_sortRequests);

      final conversations = results[1] as List<ChatConversationDto>;
      conversations.sort((a, b) {
        final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      if (!mounted) return;
      setState(() {
        _donorRequests = donorRequests;
        _conversations = conversations;
        _dashboardError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dashboardError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingDashboard = false;
        });
      }
    }
  }

  Future<void> _syncLocation({required bool showSnackBarOnError}) async {
    if (_syncingLocation) return;

    setState(() {
      _syncingLocation = true;
      _syncError = null;
    });

    try {
      final position = await LocationService.getCurrentLocation();
      await ref
          .read(authRepositoryProvider)
          .updateLocation(
            latitude: position.latitude,
            longitude: position.longitude,
          );
      if (!mounted) return;
      setState(() {
        _lastSyncedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _syncError = message;
      });
      if (showSnackBarOnError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _syncingLocation = false;
        });
      }
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    if (_updatingAvailability) return;

    setState(() {
      _updatingAvailability = true;
      _available = value;
    });

    try {
      await ref.read(authRepositoryProvider).updateAvailability(value);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _available = !value;
      });
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _updatingAvailability = false;
        });
      }
    }
  }

  String _syncTimeLabel() {
    if (_lastSyncedAt == null) {
      return 'Not synced yet';
    }
    final localTime = _lastSyncedAt!.toLocal();
    final hour = localTime.hour.toString().padLeft(2, '0');
    final minute = localTime.minute.toString().padLeft(2, '0');
    final second = localTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  int _sortRequests(DonationRequestDto a, DonationRequestDto b) {
    const urgencyOrder = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3};
    final urgencyA = urgencyOrder[a.urgency.toLowerCase()] ?? 4;
    final urgencyB = urgencyOrder[b.urgency.toLowerCase()] ?? 4;
    if (urgencyA != urgencyB) {
      return urgencyA.compareTo(urgencyB);
    }

    final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  }

  void _openRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RequestsPage(user: widget.user)),
    );
  }

  void _openChats() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatConversationsPage(user: widget.user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incomingRequests = _donorRequests
        .where((request) => request.status.toLowerCase() == 'pending')
        .take(3)
        .toList();
    final acceptedCount = _donorRequests
        .where((request) => request.status.toLowerCase() == 'accepted')
        .length;
    final pendingCount = _donorRequests
        .where((request) => request.status.toLowerCase() == 'pending')
        .length;
    final latestRequest = _donorRequests.isEmpty ? null : _donorRequests.first;
    final latestConversation = _conversations.isEmpty
        ? null
        : _conversations.first;

    final verificationStatus = widget.user.verificationStatus.toLowerCase();
    final isVerified =
        widget.user.isVerifiedDonor || verificationStatus == 'approved';
    final verificationColor = isVerified
        ? const Color(0xFF16A34A)
        : verificationStatus == 'rejected'
        ? Theme.of(context).colorScheme.error
        : const Color(0xFFF59E0B);
    final verificationLabel = isVerified
        ? 'Verified Donor'
        : verificationStatus == 'rejected'
        ? 'Verification Rejected'
        : 'Verification Pending';

    return Scaffold(
      appBar: AppBar(title: const Text('Donor Dashboard')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refreshDashboard(initialLoad: false),
          child: ListView(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Text(
                'Welcome donor ${widget.user.name}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Availability',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  _available
                                      ? 'Available now'
                                      : 'Currently unavailable',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _available,
                            onChanged: _updatingAvailability
                                ? null
                                : _toggleAvailability,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: verificationColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isVerified ? Icons.verified : Icons.hourglass_top,
                              size: 16,
                              color: verificationColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              verificationLabel,
                              style: TextStyle(
                                color: verificationColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Location synced at ${_syncTimeLabel()}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          if (_syncingLocation)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      if (_syncError != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _syncError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Incoming Requests',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _openRequests,
                            iconAlignment: IconAlignment.end,
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: const Text('See all'),
                          ),
                        ],
                      ),
                      if (_loadingDashboard && _donorRequests.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (incomingRequests.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'No incoming requests right now.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      else
                        Column(
                          children: incomingRequests.map((request) {
                            final createdLabel = request.createdAt == null
                                ? 'Unknown time'
                                : DateFormat(
                                    'dd MMM, hh:mm a',
                                  ).format(request.createdAt!.toLocal());
                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  title: Text(
                                    request.seekerName ?? 'Unknown seeker',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${request.organType.toUpperCase()} - ${request.urgency.toUpperCase()}',
                                  ),
                                  trailing: Text(
                                    createdLabel,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  onTap: _openRequests,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Donation Stats',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Total',
                      value: _donorRequests.length.toString(),
                      icon: Icons.assignment_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: 'Pending',
                      value: pendingCount.toString(),
                      icon: Icons.hourglass_top,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: 'Accepted',
                      value: acceptedCount.toString(),
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Activity',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.chat_bubble_outline),
                        title: const Text('Chat Preview'),
                        subtitle: Text(
                          latestConversation == null
                              ? 'No chat activity yet'
                              : '${latestConversation.otherUserName}: ${latestConversation.lastMessage.isEmpty ? 'No messages yet' : latestConversation.lastMessage}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _openChats,
                      ),
                      const Divider(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.inbox_outlined),
                        title: const Text('Request Preview'),
                        subtitle: Text(
                          latestRequest == null
                              ? 'No request activity yet'
                              : '${latestRequest.seekerName ?? 'Unknown seeker'} - ${latestRequest.status.toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _openRequests,
                      ),
                    ],
                  ),
                ),
              ),
              if (_dashboardError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _dashboardError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Column(
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
