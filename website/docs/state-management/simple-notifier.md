---
sidebar_position: 3
---

# SimpleNotifier

Just create a class that extends of `SimpleNotifier`

```dart
import 'package:flutter_meedu/meedu.dart';

class CounterController extends SimpleNotifier{
    int _counter = 0;
    int get counter => _counter;

    void increment(){
        _counter++;
        notify(); // notify to all listeners
    }

    // override the next method is OPTIONAL
    @override
    void dispose() {
      // YOUR CODE HERE
      super.dispose();// <-- you must call to the super method
    }
}
```

## **SimpleProvider**

Now you need to create a `provider` as a global variable using the `SimpleProvider` class.

```dart
final counterProvider = SimpleProvider(
  (ref) => CounterController(),
);
```

:::note
If you don't use lambda functions to define the callback for your provider
you must define the Generic Type

```dart
final counterProvider = SimpleProvider<CounterController>(
  (ref) {
    /// YOUR CODE HERE
    return CounterController();
  },
);
```

:::

Now you can use the `Consumer` widget to read your `CounterController`.

```dart
import 'package:flutter_meedu/ui.dart';
import 'package:flutter_meedu/meedu.dart';

final counterProvider = SimpleProvider(
  (ref) => CounterController(),
);

class CounterPage extends StatelessWidget {
  const CounterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // The Consumer widget listen the changes in your CounterController
        // and rebuild the widget when is need it
        child: Consumer(builder: (_, ref, __) {
          final controller = ref.watch(counterProvider);
          return Text("${controller.counter}");
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // you can use the read method to access to your CounterController
          counterProvider.read.increment();
        },
      ),
    );
  }
}
```

By default the `counterProvider` variable doesn't create one instance of `CounterController` until it is need it. In this case the `Consumer`
widget call to the `read` property of our `counterProvider` and check if the `CounterController` was created and return the `CounterController` that was created before or create a new `CounterController`.

The `dispose` method in our `CounterController` will be called when the `route` who created the `CounterController` is popped.

If you don't want to call to the `dispose` method when the `route` who created the `CounterController` is popped you could use.

```dart {3}
final counterProvider = SimpleProvider(
  (ref) => CounterController(),
  autoDispose: false,// <-- ADD THIS TO DISABLE THE AUTO DISPOSE
);
```

:::note
`autoDispose: false` can be used to define global states.
:::

:::danger WARNING
When you disable the `autoDispose` of your `provider` you need to handle it manually. For example
:::

```dart {18}
final counterProvider = SimpleProvider(
  (ref) => CounterController(),
  autoDispose: false,
);

class CounterPage extends StatefulWidget {
  const CounterPage({Key? key}) : super(key: key);
  @override
  _CounterPageState createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  @override
  void dispose() {
    // handle the dispose event manually
    // check if the provider has a Controller created before
    if (counterProvider.mounted) {
      counterProvider.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Consumer(builder: (_, ref, __) {
          final controller = ref.watch(counterProvider);
          return Text("${controller.counter}");
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          counterProvider.read.increment();
        },
      ),
    );
  }
}
```

### Listen the changes in your Controller

You could use the `ProviderListener` Widget to listen the changes in our `CounterController`

```dart {3-7}
 ProviderListener<CounterController>(
      provider: counterProvider,
      onChange: (context, controller) {
        // YOUR CODE HERE
        // This method is called every time that one Instance
        // of our CounterController calls to the notify() method
      },
      builder: (_, controller) => Scaffold(
        body: Center(
          // The Consumer widget listen the changes in your CounterController
          // and rebuild the widget when is need it
          child: Consumer(
            builder: (_, ref, __) {
              final controller = ref.watch(counterProvider);
              return Text("${controller.counter}");
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // you can use the read property to access to your CounterController
            counterProvider.read.increment();
          },
        ),
      ),
    )
```

:::note
if you want to listen multiples providers at the same time you can use
the `MultiProviderListener` widget.

```dart

final conterProvider = SimpleProvider(
  (_) => CounterController(),
);

final loginProvider = StateProvider<LoginController, LoginState>(
  (_) => LoginController(),
);

class MultiProviderPage extends StatelessWidget {
  const MultiProviderPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProviderListener(
      items: [
        MultiProviderListenerItem<CounterController>(
          provider: conterProvider,
          onChange: (_, controller) {
              /// ADD YOUR CODE HERE
          },
        ),
        MultiProviderListenerItem<LoginController>(
          provider: loginProvider,
          onChange: (_, controller) {
             /// ADD YOUR CODE HERE
          },
        ),
      ],
      child: YOUR_WIDGET,
    );
  }
}

```
:::

:::note
- `ProviderListener` and `MultiProviderListener` don't rebuild the widget returned by the `builder` method.
:::

Or you can listen the changes in your SimpleProvider as a `StreamSubscription`

```dart {1,5-7,12}
  StreamSubscription? _subscription;
  @override
  void initState() {
    super.initState();
    _subscription = counterProvider.read.stream.listen((_) {
      // YOUR CODE HERE
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
```

### Avoid rebuilds using the ***.select*** filter

If you have multiples `Consumer` widgets in your Views and you only want rebuild certain Consumer you can use the `.select` filter.

The next code rebuilds the first `Consumer` only when the counter is highest than 5.

:::note IMPORTANT
If you don't define the `booleanCallback` argument when you use the `.select` filter and your callback return a boolean (true or false)  your consumers and your listeners will notified when the value returned by the callback changes ( `true` to `false` or `false` to `true`).
:::

```dart {20}
class CounterController extends SimpleNotifier {
  int _counter = 0;
  int get counter => _counter;

  void increment() {
    _counter++;
    notify();
  }
}

.
.
.

Scaffold(
  body: Center(
    child: Consumer(
        builder: (_, ref, __) {
          final controller = ref.watch(
                counterProvider.select(
                  (controller) => controller.counter > 5,
                  booleanCallback: true,
                ),
            ),
          );
          return Text("${controller.counter}");
        },
    )
  ),
  floatingActionButton: FloatingActionButton(
    onPressed: () {
      // you can use the read method to access to your CounterController
      counterProvider.read.increment();
    },
  ),
)
```

:::note
Also you can use the `select` method to listen when a value has changed and rebuild your Consumer.
The next code rebuild your `Consumer` only when the `counter` value has changed in your CounterController.

```dart
Consumer(
  builder: (_, ref, __) {
    final controller = ref.watch(
      counterProvider.select((_) => _.counter),
    );
    return Text("${controller.counter}");
  },
)
```

If you want direct access to the value returned by `counterProvider.select((_) => _.counter)` you can use `ref.select`

```dart
Consumer(
  builder: (_, ref, __) {
    final counter = ref.select(
      counterProvider.select((_) => _.counter),
    );
    return Text("$counter");
  },
)
```
:::

:::note
- You can use the filters `.select , .when` in your `ProviderListener` 
or in your `MultiProviderListener`
  
  
Example:

```dart
ProviderListener<CounterController>(
  provider: counterProvider.select(
    (_) => _.counter >= 5,
    booleanCallback: true,
  ),
  onChange: (_, controller) {

  },
  builder: (_, controller) {
    return YOUR_WIDGET;
  },
);
```
:::

## ConsumerWidget
Also you can extend from `ConsumerWidget` to create a widget and listen the changes in your notifier

```dart {7}
class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: CounterView(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          counterProvider.read.increment();
        },
      ),
    );
  }
}

class CounterView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, ref) {
    final controller = ref.watch(counterProvider);
    return Text("${controller.counter}");
  }
}
```

:::success NOTE
The `ref` parameter in a `Consumer` or a `ConsumerWidget` can be used to listen multiples providers.

```dart
class CounterView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, ref) {
    final counterController = ref.watch(counterProvider);
    final loginController = ref.watch(loginProvider);
    return Text("${counterController.counter}");
  }
}
```
:::
