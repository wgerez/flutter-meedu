import 'package:flutter/widgets.dart';
import 'package:meedu/provider.dart';

RouteObserver<PageRoute> get observer => _RouterObserver.i;

class _RouterObserver extends RouteObserver<PageRoute> {
  _RouterObserver._();
  static _RouterObserver i = _RouterObserver._();

  String _getRouteName(PageRoute route) {
    return route.settings.name!;
  }

  void _checkAutoDispose(String routeName) {
    try {
      if (BaseProvider.containers.isNotEmpty) {
        final container = BaseProvider.containers.values.firstWhere(
          (e) => e.routeName == routeName,
        );
        if (container.autoDispose) {
          container.reference.dispose();
        }
      }
    } catch (_) {}
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (route is PageRoute) {
      _checkAutoDispose(this._getRouteName(route));
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    if (route is PageRoute) {
      BaseProvider.flutterCurrentRoute = this._getRouteName(route);
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (oldRoute is PageRoute) {
      _checkAutoDispose(this._getRouteName(oldRoute));
    }
  }
}
