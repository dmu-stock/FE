import 'package:flutter/widgets.dart';

import 'app_state.dart';

/// Makes [AppState] available to the widget tree.
///
/// [of] subscribes the caller to rebuilds — that is what lets the home screen
/// react to a stock registered in another (still-mounted) tab. [read] is for
/// callbacks and `initState`, where subscribing would be wrong.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found above this widget');
    return scope!.notifier!;
  }

  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found above this widget');
    return scope!.notifier!;
  }
}
