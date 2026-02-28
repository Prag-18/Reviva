import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/user_dto.dart';
import 'state/requests_controller.dart';
import 'widgets/request_status_badge.dart';

class RequestsPage extends ConsumerStatefulWidget {
  final UserDto user;

  const RequestsPage({super.key, required this.user});

  @override
  ConsumerState<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends ConsumerState<RequestsPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(requestsControllerProvider.notifier).refresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(requestsControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(requestsControllerProvider.notifier).refresh(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Requests', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 20),
                Expanded(
                  child: Builder(
                    builder: (_) {
                      if (state.loading && state.requests.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state.error != null && state.requests.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(state.error!),
                              const SizedBox(height: 10),
                              OutlinedButton(
                                onPressed: () => ref
                                    .read(requestsControllerProvider.notifier)
                                    .refresh(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }
                      if (state.requests.isEmpty) {
                        return const Center(child: Text('No requests yet'));
                      }

                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: state.requests.length,
                        itemBuilder: (context, index) {
                          final item = state.requests[index];
                          final createdAt = item.createdAt;
                          final createdLabel = createdAt == null
                              ? 'Unknown date'
                              : DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toLocal());

                          final counterpartName = widget.user.role == 'donor'
                              ? item.seekerName
                              : item.donorName;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        item.organType.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      RequestStatusBadge(status: item.status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Urgency: ${item.urgency.toUpperCase()}'),
                                  const SizedBox(height: 4),
                                  Text(
                                    'User: ${counterpartName ?? 'Unknown'}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    createdLabel,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
