import 'package:flutter/material.dart';

/// Builds [builder] only after its tab is first selected; keeps state with [AutomaticKeepAliveClientMixin].
class LazyTabChild extends StatefulWidget {
  const LazyTabChild({
    super.key,
    required this.tabIndex,
    required this.controller,
    required this.builder,
  });

  final int tabIndex;
  final TabController controller;
  final Widget Function() builder;

  @override
  State<LazyTabChild> createState() => _LazyTabChildState();
}

class _LazyTabChildState extends State<LazyTabChild>
    with AutomaticKeepAliveClientMixin {
  bool _activated = false;

  @override
  bool get wantKeepAlive => _activated;

  @override
  void initState() {
    super.initState();
    _maybeActivate(widget.controller.index);
    widget.controller.addListener(_onTabChanged);
  }

  @override
  void didUpdateWidget(covariant LazyTabChild oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTabChanged);
      widget.controller.addListener(_onTabChanged);
    }
    _maybeActivate(widget.controller.index);
  }

  void _onTabChanged() => _maybeActivate(widget.controller.index);

  void _maybeActivate(int index) {
    if (_activated || index != widget.tabIndex) return;
    setState(() => _activated = true);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTabChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_activated) return const SizedBox.shrink();
    return widget.builder();
  }
}
