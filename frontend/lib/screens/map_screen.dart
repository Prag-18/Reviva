import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../app/providers.dart';
import '../core/utils/location_service.dart';
import '../models/donor_dto.dart';

class MapScreen extends ConsumerStatefulWidget {
  final String organType;
  final double radiusKm;

  const MapScreen({super.key, required this.organType, required this.radiusKm});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  static const LatLng _fallbackCenter = LatLng(12.8211, 80.0451);

  GoogleMapController? _mapController;
  Set<Marker> _markers = <Marker>{};
  LatLng _center = _fallbackCenter;
  bool _loading = true;
  bool _myLocationEnabled = false;
  bool _refreshInProgress = false;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDonors(initialLoad: true));
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => unawaited(_loadDonors(initialLoad: false)),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadDonors({required bool initialLoad}) async {
    if (_refreshInProgress) return;
    _refreshInProgress = true;

    if (initialLoad && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final position = await LocationService.getCurrentLocation();
      final seekerLocation = LatLng(position.latitude, position.longitude);

      final donors = await ref
          .read(donorRepositoryProvider)
          .fetchNearbyDonors(
            latitude: position.latitude,
            longitude: position.longitude,
            organType: widget.organType,
            radiusKm: widget.radiusKm,
          );

      final markers = _buildMarkers(donors, seekerLocation);

      if (!mounted) return;
      setState(() {
        _center = seekerLocation;
        _markers = markers;
        _myLocationEnabled = true;
        _loading = false;
        _error = null;
      });

      if (initialLoad && _mapController != null) {
        unawaited(
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: seekerLocation, zoom: 13.5),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      _refreshInProgress = false;
    }
  }

  Set<Marker> _buildMarkers(List<DonorDto> donors, LatLng seekerLocation) {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('me'),
        position: seekerLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You'),
      ),
    };

    for (final donor in donors) {
      final lat = donor.latitude;
      final lon = donor.longitude;
      if (lat == null || lon == null) continue;

      markers.add(
        Marker(
          markerId: MarkerId(donor.id),
          position: LatLng(lat, lon),
          infoWindow: InfoWindow(
            title: donor.name,
            snippet: '${donor.distanceKm.toStringAsFixed(1)} km away',
          ),
        ),
      );
    }

    return markers;
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    unawaited(
      controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _center, zoom: 13.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final donorCount = _markers.where((m) => m.markerId.value != 'me').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Donors Map'),
        actions: [
          IconButton(
            onPressed: () => _loadDonors(initialLoad: false),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              '${widget.organType.toUpperCase()} within ${widget.radiusKm.toStringAsFixed(0)} km - $donorCount donors',
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _center,
                    zoom: 12,
                  ),
                  markers: _markers,
                  myLocationEnabled: _myLocationEnabled,
                  myLocationButtonEnabled: _myLocationEnabled,
                  compassEnabled: true,
                ),
                if (_loading)
                  const Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: LinearProgressIndicator(),
                  ),
                if (_error != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 16,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
