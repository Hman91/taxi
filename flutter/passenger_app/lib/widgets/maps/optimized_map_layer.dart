import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../maps/light_elegant_map_style.dart';

/// Isolated map surface: parent sheet/UI can rebuild without recreating [GoogleMap].
class OptimizedMapLayer extends StatefulWidget {
  const OptimizedMapLayer({
    super.key,
    required this.initialCameraPosition,
    required this.markers,
    required this.polylines,
    this.padding = EdgeInsets.zero,
    this.myLocationEnabled = false,
    this.onMapCreated,
    this.onCameraMoveStarted,
  });

  final CameraPosition initialCameraPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final EdgeInsets padding;
  final bool myLocationEnabled;
  final void Function(GoogleMapController controller)? onMapCreated;
  final VoidCallback? onCameraMoveStarted;

  @override
  State<OptimizedMapLayer> createState() => _OptimizedMapLayerState();
}

class _OptimizedMapLayerState extends State<OptimizedMapLayer>
    with AutomaticKeepAliveClientMixin {
  GoogleMapController? _controller;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RepaintBoundary(
      child: GoogleMap(
        key: const ValueKey('optimized_map_layer'),
        style: kPassengerLightMapStyleJson,
        initialCameraPosition: widget.initialCameraPosition,
        markers: widget.markers,
        polylines: widget.polylines,
        mapToolbarEnabled: false,
        zoomControlsEnabled: false,
        compassEnabled: false,
        myLocationButtonEnabled: false,
        myLocationEnabled: widget.myLocationEnabled,
        buildingsEnabled: true,
        padding: widget.padding,
        onCameraMoveStarted: widget.onCameraMoveStarted,
        onMapCreated: (c) {
          _controller = c;
          widget.onMapCreated?.call(c);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
