import 'dart:async';

import 'package:meedu/rx.dart';
import 'package:test/test.dart';

void main() {
  test('rx notifier', () async {
    var completer = Completer<int>();
    var observer = RxNotifier();
    RxNotifier.proxy = observer;
    expect(observer.canUpdate, false);
    final counter = 0.obs;

    observer.addListener(counter);
    expect(observer.canUpdate, true);

    observer.listen((_) {
      completer.complete(_);
    });
    observer.subject.controller.sink.add(2);
    expect(counter.value, 0);
    await observer.close();

    expect(observer.canUpdate, false);
    expect(await completer.future, 2);
  });
}
