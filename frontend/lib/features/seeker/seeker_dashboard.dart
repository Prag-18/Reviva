import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/donor_dto.dart';
import '../../models/user_dto.dart';
import 'state/find_donors_controller.dart';
import 'widgets/donor_shimmer_list.dart';

final List<String> organTypes = [
  'blood',
  'kidney',
  'liver',
  'heart',
  'cornea',
  'bone_marrow',
];

class SeekerDashboard extends ConsumerWidget {
  final UserDto user;

  const SeekerDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(findDonorsControllerProvider);
    final controller = ref.read(findDonorsControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Find Donors', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 10),
              Text(
                'Search nearby available donors instantly',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              _OrganSelector(
                selectedOrgan: state.organType,
                onChanged: controller.setOrganType,
              ),
              const SizedBox(height: 12),
              _RadiusSelector(
                radiusKm: state.radiusKm,
                onChanged: controller.setRadius,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.loading ? null : controller.findDonors,
                  child: const Text('Search Nearby Donors'),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Builder(
                  builder: (_) {
                    if (state.loading) return const DonorShimmerList();

                    if (state.error != null) {
                      return _ErrorView(
                        message: state.error!,
                        onRetry: controller.findDonors,
                      );
                    }

                    if (state.donors.isEmpty) {
                      return const _EmptyDonorsView();
                    }

                    return ListView.builder(
                      itemCount: state.donors.length,
                      itemBuilder: (context, index) {
                        final donor = state.donors[index];
                        return _DonorCard(
                          donor: donor,
                          organType: state.organType,
                          onRequest: () async {
                            try {
                              await controller.sendRequest(donor.id);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Request sent successfully'),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          },
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
    );
  }
}

class _OrganSelector extends StatelessWidget {
  final String selectedOrgan;
  final ValueChanged<String> onChanged;

  const _OrganSelector({required this.selectedOrgan, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButton<String>(
        value: selectedOrgan,
        isExpanded: true,
        underline: const SizedBox(),
        items: organTypes
            .map(
              (organ) => DropdownMenuItem(
                value: organ,
                child: Text(organ.replaceAll('_', ' ').toUpperCase()),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _RadiusSelector extends StatelessWidget {
  final double radiusKm;
  final ValueChanged<double> onChanged;

  const _RadiusSelector({required this.radiusKm, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Radius: ${radiusKm.toStringAsFixed(0)} km'),
        Slider(
          value: radiusKm,
          min: 2,
          max: 30,
          divisions: 14,
          label: '${radiusKm.toStringAsFixed(0)} km',
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _DonorCard extends StatelessWidget {
  final DonorDto donor;
  final String organType;
  final VoidCallback onRequest;

  const _DonorCard({
    required this.donor,
    required this.organType,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              donor.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              '${donor.bloodGroup ?? 'N/A'} - ${donor.distanceKm.toStringAsFixed(1)} km away',
            ),
            const SizedBox(height: 4),
            Text('Donation type: ${(donor.donationType ?? organType).toUpperCase()}'),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onRequest,
                child: const Text('Send Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDonorsView extends StatelessWidget {
  const _EmptyDonorsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 44),
          const SizedBox(height: 8),
          Text(
            'No donors found in this radius',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          const Text('Try increasing the radius or changing organ type.'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 42, color: Colors.red),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
