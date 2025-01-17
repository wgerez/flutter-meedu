// ignore_for_file: avoid_dynamic_calls

import 'package:meedu/provider.dart';
import 'package:meedu/state.dart';

typedef _BuildWhen<S> = bool Function(S prev, S current);
typedef _BuildBySelect<Notifier, Result> = Result Function(Notifier);

/// enum used to identifier filters used in a provider
enum Filter {
  /// .select filter for SimpleProvider and StateProvider
  select,

  /// .when filter fot StateProvider
  /// this filter only can be  used with ref.watch
  when,
}

/// class to save a Notifier, the listener and the rebuild function
class Target<Notifier, Result> extends ListeneableProvider<Notifier> {
  // ignore: public_member_api_docs
  Target(this.notifier);

  /// a SimpleNotifier or a StateNotifier
  final Notifier notifier;

  /// listener to listen the changes in our Notifiers
  late void Function(dynamic) listener;

  /// function to rebuild the Consumer
  void Function()? rebuild;

  /// used to store the value returned by .select or .when
  late Result selectValue;

  /// callback defined when a filter is used
  late Function callback;

  /// filter type
  late Filter filter;

  /// if the filter is a selected and we only want to
  /// rebuild the consumer when the callback returns true
  late bool listenWhenTheCallbackReturnsTrue;
}

/// extension for SimpleProvider
extension SimpleProviderExt<Notifier> on SimpleProvider<Notifier> {
  /// use this method to rebuild your Consumer when a value has changed
  /// or you can use a boolean condition. Check the documentation for more info.
  ///
  /// [booleanCallback] If your callback returns a boolean and you want to
  /// rebuild your consumers or notify to your listeners only when the boolean
  /// value is true you can set [booleanCallback] as true
  ///
  /// EXAMPLE:
  /// ```dart
  ///    final controller = ref.watch(
  ///    provider.select(
  ///      (_) => _.user != null,
  ///      booleanCallback: true,
  ///    ),
  ///  );
  /// ```
  ///
  Target<Notifier, Result> select<Result>(
    _BuildBySelect<Notifier, Result> callback, {
    bool booleanCallback = false,
  }) {
    // get the  Notifier attached to this SimpleProvider
    final target = Target<Notifier, Result>(read);
    target.filter = Filter.select;
    target.callback = callback;
    target.listenWhenTheCallbackReturnsTrue = booleanCallback;
    return target;
  }
}

/// extension for StateProvider
extension StateProviderExt<Notifier extends StateNotifier<S>, S>
    on StateProvider<Notifier, S> {
  /// use this method to rebuild your Consumer using the previous state and the current
  /// state to return a boolean
  Target<Notifier, bool> when(_BuildWhen<S> callback) {
    final target = Target<Notifier, bool>(read);
    target.filter = Filter.when;
    target.callback = callback;
    target.listenWhenTheCallbackReturnsTrue = false;
    return target;
  }

  /// use this method to rebuild your Consumer when a value in the state has changed
  /// or you can use a boolean condition. Check the documentation for more info.
  ///
  /// [booleanCallback] If your callback returns a boolean and you want to
  /// rebuild your consumers or notify to your listeners only when the boolean
  /// value is true you can set [booleanCallback] as true
  ///
  /// EXAMPLE:
  /// ```dart
  ///    final controller = ref.watch(
  ///    provider.select(
  ///      (_) => _.user != null,
  ///      booleanCallback: true,
  ///    ),
  ///  );
  /// ```
  ///
  Target<Notifier, Result> select<Result>(
    _BuildBySelect<S, Result> callback, {
    bool booleanCallback = false,
  }) {
    final target = Target<Notifier, Result>(read);
    target.filter = Filter.select;
    target.callback = callback;
    target.listenWhenTheCallbackReturnsTrue = booleanCallback;
    return target;
  }
}

/// create the listener for provider.select filter (SimpleProvider)
void createSimpleSelectListener(Target target) {
  final notifier = target.notifier;
  // get an initial value using the callback
  dynamic prevValue = target.callback(notifier);
  target.selectValue = prevValue;

  // listener with  the logic to rebuild the Consumer
  // ignore: prefer_function_declarations_over_variables
  final listener = (_) {
    final value = target.callback(notifier);
    if (target.listenWhenTheCallbackReturnsTrue) {
      assert(
        value is bool,
        'The value returned by the callback must be a boolean because '
        'listenWhenTheCallbackReturnsTrue is true',
      );
    }

    target.selectValue = value;
    bool allowRebuild = false;
    if (value is bool && target.listenWhenTheCallbackReturnsTrue) {
      allowRebuild = value;
    } else if (prevValue != value) {
      allowRebuild = true;
    }

    // check if the value has changed
    if (allowRebuild && target.rebuild != null) {
      target.rebuild!(); // rebuild the Consumer
    }
    prevValue = value;
  };
  // save the listener to be added to our Notifier later
  target.listener = listener;
}

/// create the listener for provider.select filter (StateProvider)
void createStateSelectListener(Target target) {
  dynamic prevValue = target.callback(target.notifier.state);
  target.selectValue = prevValue;

  // ignore: prefer_function_declarations_over_variables
  final listener = (newState) {
    final value = target.callback(target.notifier.state);
    if (target.listenWhenTheCallbackReturnsTrue) {
      assert(
        value is bool,
        'The value returned by the callback must be a boolean because '
        'listenWhenTheCallbackReturnsTrue is true',
      );
    }

    target.selectValue = value;

    bool allowRebuild = false;
    if (value is bool && target.listenWhenTheCallbackReturnsTrue) {
      allowRebuild = value;
    } else if (prevValue != value) {
      allowRebuild = true;
    }

    // check if the value has changed
    if (allowRebuild && target.rebuild != null) {
      target.rebuild!();
    }
    prevValue = value;
  };
  target.listener = listener;
}

/// create the listener for provider.when filter
void createWhenListener(Target target) {
  final notifier = target.notifier as StateNotifier;
  target.selectValue = target.callback(notifier.state, notifier.state);

  // ignore: prefer_function_declarations_over_variables
  final listener = (newState) {
    // rebuild the Consumer using the boolean returned by the callback
    final allowRebuild = target.callback(notifier.oldState, newState);
    target.selectValue = allowRebuild;
    if (allowRebuild) {
      if (target.rebuild != null) {
        target.rebuild!();
      }
    }
  };
  target.listener = listener;
}
