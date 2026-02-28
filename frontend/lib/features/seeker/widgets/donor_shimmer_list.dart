import 'package:flutter/material.dart';

class DonorShimmerList extends StatefulWidget {
  const DonorShimmerList({super.key});

  @override
  State<DonorShimmerList> createState() => _DonorShimmerListState();
}

class _DonorShimmerListState extends State<DonorShimmerList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.35 + (_controller.value * 0.35);
        return ListView.builder(
          itemCount: 4,
          itemBuilder: (context, index) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: opacity),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      },
    );
  }
}
