import '../../provider.dart';

class ProviderContainer {
  /// int used as key into the Map [ProviderScope.containers]
  final int providerHashCode;

  /// could be a [SimpleNotifier] or a [StateNotifier]
  final dynamic element;

  /// references used to pass params to the notifier
  /// and this contains the callback to dispose the notifier
  final ProviderReference reference;

  /// the route name who created this Notifier
  final String? routeName;

  /// used to known if the [notifier] must be disposed when the [routeName] is distroyed
  final bool autoDispose;

  ProviderContainer({
    required this.providerHashCode,
    required this.element,
    required this.reference,
    required this.autoDispose,
    required this.routeName,
  });
}
