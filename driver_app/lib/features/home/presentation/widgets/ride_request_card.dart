import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/services/socket_service.dart';
import '../providers/incoming_requests_provider.dart';

class RideRequestCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> request;

  const RideRequestCard({super.key, required this.request});

  @override
  ConsumerState<RideRequestCard> createState() => _RideRequestCardState();
}

class _RideRequestCardState extends ConsumerState<RideRequestCard> with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> _controller = Completer();
  late AnimationController _timerController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Default timeout duration (reduced to sync with backend)
  static const int _timeoutSeconds = 15;

  @override
  void initState() {
    super.initState();
    _setupMapData();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _timeoutSeconds),
    )..reverse(from: 1.0);
  }

  // ... (dispose and map setup unchanged) ...
  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  void _setupMapData() {
    final startLat = double.parse(widget.request['start']['lat'].toString());
    final startLng = double.parse(widget.request['start']['lng'].toString());
    final endLat = double.parse(widget.request['end']['lat'].toString());
    final endLng = double.parse(widget.request['end']['lng'].toString());

    final startPos = LatLng(startLat, startLng);
    final endPos = LatLng(endLat, endLng);

    _markers = {
      Marker(
        markerId: const MarkerId('start'),
        position: startPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: endPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    if (widget.request['polyline'] != null) {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: _decodePolyline(widget.request['polyline']),
          color: const Color(0xFF1A77F6),
          width: 5,
        ),
      };
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  void _acceptRide() {
    final rideId = widget.request['ride_id'];
    ref.read(socketServiceProvider).socket.emit('driver:accept_request', {'ride_id': rideId});
  }

   @override
  Widget build(BuildContext context) {
    final distance = widget.request['distance'] != null 
        ? (widget.request['distance'] / 1000).toStringAsFixed(1) 
        : '-';
    final duration = widget.request['duration'] != null 
        ? (widget.request['duration'] / 60).toStringAsFixed(0) 
        : '-';
    final fare = widget.request['fare_estimate'] ?? '-';
    final addressStart = widget.request['start']['address'] ?? 'incoming_request.start_location'.tr();
    final addressEnd = widget.request['end']['address'] ?? 'incoming_request.end_location'.tr();
    
    // Parse Options
    final options = widget.request['options'] as Map<String, dynamic>? ?? {};
    final bool openTaximeter = options['open_taximeter'] == true;
    final bool hasPet = options['has_pet'] == true;
    final String paymentMethod = widget.request['payment_method']?.toString() ?? 'nakit';
    final bool isCash = paymentMethod == 'nakit';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge, 
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
           // 1. Header & Map (Top Half)
           Stack(
             children: [
               SizedBox(
                 height: 180, // Reduced height
                 child: GoogleMap(
                   initialCameraPosition: CameraPosition(
                    target: _markers.isNotEmpty ? _markers.first.position : const LatLng(0,0),
                     zoom: 13,
                   ),
                   markers: _markers,
                   polylines: _polylines,
                   zoomControlsEnabled: false,
                   liteModeEnabled: false,
                   myLocationButtonEnabled: false,
                   onMapCreated: (controller) {
                     _controller.complete(controller);
                     if (_markers.isNotEmpty) {
                       Future.delayed(const Duration(milliseconds: 300), () {
                         controller.animateCamera(CameraUpdate.newLatLngBounds(
                           _boundsFromLatLngList(_markers.map((m) => m.position).toList()),
                           60,
                         ));
                       });
                     }
                   },
                 ),
               ),
               // Info Badge on Map (Replacing "New Ride")
               Positioned(
                 top: 16,
                 right: 16,
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                   decoration: BoxDecoration(
                     color: const Color(0xFF1A77F6), // Theme Blue
                     borderRadius: BorderRadius.circular(30),
                     boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A77F6).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                     ],
                   ),
                   child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         const Icon(Icons.access_time_filled, size: 14, color: Colors.white70),
                         const SizedBox(width: 4),
                         Text(
                         '$duration dk',
                         style: const TextStyle(
                           color: Colors.white,
                           fontWeight: FontWeight.bold,
                           fontSize: 13,
                         ),
                       ),
                       Container(
                         height: 12, 
                         width: 1, 
                         color: Colors.white24, 
                         margin: const EdgeInsets.symmetric(horizontal: 8),
                       ),
                       const Icon(Icons.directions_car, size: 14, color: Colors.white70),
                       const SizedBox(width: 4),
                       Text(
                         '$distance km',
                         style: const TextStyle(
                           color: Colors.white,
                           fontWeight: FontWeight.bold,
                           fontSize: 13,
                         ),
                       ),
                      ],
                   ),
                 ),
               ),
             ],
           ),

           // 2. Info Section (Bottom Half)
           Padding(
             padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
             child: Column(
               children: [
                 // Price and Payment Method Row
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   crossAxisAlignment: CrossAxisAlignment.center,
                   children: [
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             'incoming_request.estimated_earnings'.tr(),
                             style: TextStyle(
                               color: Colors.grey[600],
                               fontSize: 12,
                               fontWeight: FontWeight.w600,
                             ),
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                           ),
                           const SizedBox(height: 4),
                           Row(
                             crossAxisAlignment: CrossAxisAlignment.center,
                             children: [
                               Flexible(
                                 child: FittedBox(
                                   fit: BoxFit.scaleDown,
                                   alignment: Alignment.centerLeft,
                                   child: Text(
                                     '₺$fare',
                                     style: const TextStyle(
                                       fontSize: 34,
                                       fontWeight: FontWeight.w900,
                                       color: Colors.black87,
                                       height: 1.0,
                                       letterSpacing: -1.0,
                                     ),
                                   ),
                                 ),
                               ),
                               const SizedBox(width: 12),
                               // Payment Method Text ONLY (No Background)
                               Text(
                                 isCash ? 'Nakit' : 'POS',
                                 style: TextStyle(
                                   color: isCash ? const Color(0xFF2E7D32) : const Color(0xFF7B1FA2),
                                   fontWeight: FontWeight.w900, // Extra bold
                                   fontSize: 16, // Larger font
                                   letterSpacing: 0.5,
                                 ),
                               ),
                             ],
                           ),
                         ],
                       ),
                     ),
                     // Removed old blue info box from here
                   ],
                 ),
                 
                 // Options Chips (Taximeter / Pet) - Modern Thin Border
                 if (openTaximeter || hasPet) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (openTaximeter)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calculate_outlined, size: 16, color: Colors.grey[700]),
                                const SizedBox(width: 6),
                                Text(
                                  'incoming_request.open_taximeter'.tr(),
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                                ),
                              ],
                            ),
                          ),
                        if (hasPet)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.pets, size: 16, color: Colors.grey[700]),
                                const SizedBox(width: 6),
                                Text(
                                  'incoming_request.pet'.tr(),
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                 ],

                 const SizedBox(height: 24),

                 // Visual Address Timeline (Updated Icons/Colors)
                 Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     // Timeline Line
                     Column(
                       children: [
                         // Start Icon: Blue Circle
                         const Icon(Icons.radio_button_checked, color: Color(0xFF1A77F6), size: 20),
                         Container(
                           width: 2,
                           height: 40, // Slightly taller to accommodate multiline text if needed
                           color: Colors.black, // Changed to Black
                           margin: const EdgeInsets.symmetric(vertical: 2),
                         ),
                         // End Icon: Blue Pin
                         const Icon(Icons.location_on, color: Color(0xFF1A77F6), size: 20),
                       ],
                     ),
                     const SizedBox(width: 16),
                     // Addresses
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            _buildAddressText(addressStart, isTitle: true), // Force Title/Bold
                            const SizedBox(height: 24), 
                            _buildAddressText(addressEnd, isTitle: true),   // Force Title/Bold
                         ],
                       ),
                     ),
                   ],
                 ),

                 const SizedBox(height: 32),

                 // Accept Button (Unchanged style)
                 SizedBox(
                   width: double.infinity,
                   height: 56,
                   child: ElevatedButton(
                     onPressed: _acceptRide,
                     style: ElevatedButton.styleFrom(
                       backgroundColor: const Color(0xFF1A77F6), // Theme Blue
                       foregroundColor: Colors.white,
                       elevation: 0,
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(16),
                       ),
                     ),
                     child: Text(
                       'incoming_request.accept'.tr(),
                       style: const TextStyle(
                         fontSize: 18,
                         fontWeight: FontWeight.bold,
                         letterSpacing: 1.0,
                       ),
                     ),
                   ),
                 ),
               ],
             ),
           ),
           
           const SizedBox(height: 24),
           
            AnimatedBuilder(
              animation: _timerController,
              builder: (context, child) {
                final val = _timerController.value;
                Color? color;
                if (val > 0.5) {
                  color = Color.lerp(Colors.amber, Colors.green, (val - 0.5) * 2);
                } else {
                  color = Color.lerp(Colors.red, Colors.amber, val * 2);
                }

                return LinearProgressIndicator(
                  value: val,
                  backgroundColor: Colors.grey[100],
                  valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.green),
                  minHeight: 6,
                );
              },
            ),
         ],
      ),
    );
  }

  Widget _buildAddressText(String text, {required bool isTitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          maxLines: 2, // Allow up to 2 lines
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16, // Increased from 15
            fontWeight: FontWeight.bold, // Always bold as requested
            color: Colors.black87, // Stronger color
            height: 1.3,
          ),
        ),
      ],
    );
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    if (list.isEmpty) return LatLngBounds(northeast: const LatLng(0,0), southwest: const LatLng(0,0));
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
  }
}
