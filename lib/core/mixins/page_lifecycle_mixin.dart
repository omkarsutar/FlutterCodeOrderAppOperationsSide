import 'package:flutter/material.dart';

/// Mixin to help pages manage their lifecycle and pause/resume operations
/// when they are obscured by other pages in the navigation stack.
///
/// Usage:
/// ```dart
/// class MyPage extends StatefulWidget with PageLifecycleMixin {
///   @override
///   void onPageResumed() {
///     // Resume data fetching
///   }
///
///   @override
///   void onPagePaused() {
///     // Pause data fetching
///   }
/// }
/// ```
mixin PageLifecycleMixin<T extends StatefulWidget> on State<T>
    implements RouteAware {
  RouteObserver<ModalRoute<dynamic>>? _routeObserver;
  bool _isPageVisible = true;

  /// Whether the page is currently visible (not obscured by another page)
  bool get isPageVisible => _isPageVisible;

  /// Called when the page becomes visible
  void onPageResumed() {}

  /// Called when the page is obscured by another page
  void onPagePaused() {}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeObserver = RouteObserver<ModalRoute<dynamic>>();
    _routeObserver?.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _routeObserver?.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    // Page was pushed onto the navigator
    _isPageVisible = true;
    onPageResumed();
  }

  @override
  void didPopNext() {
    // Page became visible again after a page was popped
    _isPageVisible = true;
    onPageResumed();
  }

  @override
  void didPushNext() {
    // Another page was pushed on top of this page
    _isPageVisible = false;
    onPagePaused();
  }

  @override
  void didPop() {
    // This page was popped
    _isPageVisible = false;
  }
}
