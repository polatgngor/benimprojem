import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../cancellation_reason_sheet.dart';
import 'package:easy_localization/easy_localization.dart';

class SearchingRideSheet extends ConsumerWidget {
  const SearchingRideSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      key: const ValueKey('searching'),
      children: [
        const SizedBox(height: 12),
        // Custom Glowing Progress Bar
        const _GlowingProgressIndicator(),
        const SizedBox(height: 20),
        
        Text(
          'sheet.searching.title'.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'sheet.searching.desc'.tr(),
          style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const CancellationReasonSheet(),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.red.withOpacity(0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              'sheet.searching.cancel'.tr(),
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowingProgressIndicator extends StatefulWidget {
  const _GlowingProgressIndicator();

  @override
  State<_GlowingProgressIndicator> createState() => _GlowingProgressIndicatorState();
}

class _GlowingProgressIndicatorState extends State<_GlowingProgressIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1, milliseconds: 500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(3),
      ),
      child: ClipRRect( 
        borderRadius: BorderRadius.circular(3),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Bar moves from left to right
                final double start = -0.4;
                final double end = 1.4;
                final double pos = start + (end - start) * _controller.value;
                
                return Stack(
                  clipBehavior: Clip.none, 
                  children: [
                     Positioned(
                      left: pos * width,
                      width: width * 0.35, 
                      top: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity(0.8), // Glow
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ]
                        ),
                      ),
                     )
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
