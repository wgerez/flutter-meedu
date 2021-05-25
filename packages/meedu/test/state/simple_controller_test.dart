import 'dart:async';

import 'package:meedu/meedu.dart';
import 'package:test/test.dart';

typedef _Subscriber = void Function(List<String>);
void main() {
  test('SimpleController', () async {
    const times = 50;
    final Completer completer = Completer();
    final c = Controller();
    int value = c.counter;
    expect(value, 0);
    c.onInit();
    c.onAfterFirstLayout();
    expect(c.hasListeners, false);
    final _Subscriber subscribe = (List<String> listeners) {
      value = c.counter;
      if (value == times) {
        completer.complete();
      }
    };
    c.addListener(subscribe);
    expect(c.hasListeners, true);
    for (int i = 1; i <= times; i++) {
      c.counter = i;
      c.notify();
    }
    await completer.future;
    expect(value, times);
    c.removeListener(subscribe);
    c.onDispose();
    expect(c.disposed, true);
    expect(() {
      c.notify();
    }, throwsA(isA<AssertionError>()));
  });
}

class Controller extends SimpleNotifier {
  int counter = 0;

  @override
  void onInit() {
    super.onInit();
    print("😜 onInit");
  }

  @override
  void onAfterFirstLayout() {
    super.onAfterFirstLayout();
    print("😜 afterFirstLayout");
  }

  @override
  void onDispose() {
    print("😜 onDispose");
    super.onDispose();
  }
}
