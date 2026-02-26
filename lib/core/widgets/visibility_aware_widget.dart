import 'package:flutter/material.dart';

/// Widget that only builds its child when it's the top route in the navigator.
/// This prevents background pages from rebuilding and making API calls.
///
/// Usage:
/// ```dart
/// VisibilityAwareWidget(
///   child: FutureBuilder(
///     future: fetchData(),
///     builder: (context, snapshot) => ...
///   ),
/// )
/// ```
class VisibilityAwareWidget extends StatefulWidget {
  final Widget child;
  final Widget Function()? placeholderBuilder;

  const VisibilityAwareWidget({
    super.key,
    required this.child,
    this.placeholderBuilder,
  });

  @override
  State<VisibilityAwareWidget> createState() => _VisibilityAwareWidgetState();
}

class _VisibilityAwareWidgetState extends State<VisibilityAwareWidget>
    with RouteAware {
  final RouteObserver<ModalRoute<dynamic>> _routeObserver =
      RouteObserver<ModalRoute<dynamic>>();
  bool _isVisible = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      _routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    _routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    setState(() => _isVisible = true);
  }

  @override
  void didPopNext() {
    // Page became visible again
    setState(() => _isVisible = true);
  }

  @override
  void didPushNext() {
    // Another page was pushed on top
    setState(() => _isVisible = false);
  }

  @override
  void didPop() {
    setState(() => _isVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return widget.placeholderBuilder?.call() ?? const SizedBox.shrink();
    }
    return widget.child;
  }
}
