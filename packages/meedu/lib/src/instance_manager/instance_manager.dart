import '../providers/base_provider.dart';

part 'injectable.dart';

/// return an instance of _Get for the dependency injection module
_Get get Get => _Get.i;

/// Singleton to save dependencies
class _Get {
  /// private contructor
  _Get._();

  static _Get? _instance;

  static _Get get i {
    _instance ??= _Get._();
    return _instance!;
  }

  /// used to save singletons using put or lazyPut
  final Map<String, Singleton> _vars = {};
  Map<String, Singleton> get dependencies => _vars;

  /// Holds a reference to every registered callback when using
  /// [Get.i.lazyPut()]
  final Map<String, _Lazy> _lazyVars = {};

  /// used to save factory dependencies
  final Map<String, _Factory> _factoryVars = {};

  /// used to store async factory builders
  final Map<String, _AsyncFactory> _asyncVars = {};

  /// Generates the key based on [type] (and optionally a [name])
  /// to register an Instance Builder in the hashmap.
  String _getKey(Type type, String? name) {
    return name == null ? type.toString() : type.toString() + name;
  }

  /// check if one dependency is available to call to the find method
  bool has<T>({String? tag}) {
    final key = _getKey(T, tag);
    final inVars = _vars.containsKey(key);
    if (inVars) return true;
    final inFactoryVars = _factoryVars.containsKey(key);
    if (inFactoryVars) return true;
    final inLazyVars = _lazyVars.containsKey(key);
    return inLazyVars;
  }

  //
  //
  // --------------------------------------------------------------------------------------------//
  // --------------------------------------------------------------------------------------------//
  // --------------------------------------------------------------------------------------------//
  //
  //

  /// Insert an Instance into the hashmap
  ///
  /// [autoRemove] set this value to true when you  want to remove
  /// this dependency when the route who creates this dependency
  /// is popped
  ///
  /// [onRemove] callback to be called when this dependency is removed
  void put<T>(
    T value, {
    String? tag,
    bool autoRemove = false,
    _RemoveCallback<T>? onRemove,
  }) {
    final key = _getKey(T, tag);
    _vars[key] = Singleton<T>(
      value,
      autoRemove: autoRemove,
      onRemove: onRemove,
    );
  }

  /// register a new factory callback witch must return a Future
  ///
  /// every time that `asyncFind` is called this callback will be excecuted
  void asyncPut<T>(_AsyncBuilderCallback<T> builder, {String? tag}) {
    final key = _getKey(T, tag);
    _asyncVars.putIfAbsent(
      key,
      () => _AsyncFactory<T>(builder),
    );
  }

  /// register a new factory callback
  ///
  /// every time that `factoryFind` is called this callback will be excecuted
  void factoryPut<T>(_FactoryBuilderCallback<T> builder, {String? tag}) {
    final key = _getKey(T, tag);
    _factoryVars.putIfAbsent(
      key,
      () => _Factory<T>(builder),
    );
  }

  /// Creates a new Instance<S> lazily from the [<S>builder()] callback.
  ///
  /// [autoRemove] set this value to true when you  want to remove
  /// this dependency when the route who creates this dependency
  /// is popped
  ///
  /// [onRemove] callback to be called when this dependency is removed
  void lazyPut<T>(
    _LazyBuilderCallback<T> builder, {
    String? tag,
    bool autoRemove = false,
    _RemoveCallback<T>? onRemove,
  }) {
    final key = _getKey(T, tag);
    _lazyVars.putIfAbsent(
      key,
      () => _Lazy<T>(
        builder,
        autoRemove: autoRemove,
        onRemove: onRemove,
      ),
    );
  }

  //
  //
  // --------------------------------------------------------------------------------------------//
  // --------------------------------------------------------------------------------------------//
  // --------------------------------------------------------------------------------------------//
  //
  //

  /// Search and return one instance T from the hashmap
  T find<T>({String? tag}) {
    final key = _getKey(T, tag);
    // check if the dependency was already injected
    final inVars = _vars.containsKey(key);
    if (inVars) {
      return _vars[key]!.dependency as T;
    }
    // if the dependency is a lazy
    final inLazyVars = _lazyVars.containsKey(key);
    if (inLazyVars) {
      final lazy = _lazyVars[key]!;
      final dependency = lazy.builder();

      _vars[key] = Singleton<T>(
        dependency,
        autoRemove: lazy.autoRemove,
        onRemove: (lazy as dynamic).onRemove,
      );
      return dependency;
    }

    throw AssertionError(
      'Cannot find $key, make sure call to Get.put<${T.toString()}>() or Get.lazyPut<${T.toString()}>() before call find.',
    );
  }

  /// Search and return allways a new instance of T
  T factoryFind<T>({Object? arguments, String? tag}) {
    final key = _getKey(T, tag);
    // check if the dependency is a factory
    final inFactoryVars = _factoryVars.containsKey(key);
    if (inFactoryVars) {
      return (_factoryVars[key] as _Factory<T>).builder(arguments);
    }

    throw AssertionError(
      'Cannot find $key, make sure call to Get.factoryPut<${T.toString()}>() before call factoryFind.',
    );
  }

  /// Search and return allways a new instance of Future<T>
  Future<T> asyncFind<T>({Object? arguments, String? tag}) {
    final key = _getKey(T, tag);
    // check if the dependency is a factory
    final inAsyncVars = _asyncVars.containsKey(key);
    if (inAsyncVars) {
      return (_asyncVars[key] as _AsyncFactory<T>).builder(arguments);
    }

    throw AssertionError(
      'Cannot find $key, make sure call to Get.asyncPut<${T.toString()}>() before call asyncFind.',
    );
  }

  //
  //
  // --------------------------------------------------------------------------------------------//
  // --------------------------------------------------------------------------------------------//
  // --------------------------------------------------------------------------------------------//
  //
  //

  /// removes an instance from the hasmap
  T? remove<T>({String? tag}) {
    final key = _getKey(T, tag);
    final _singleton = _vars.remove(key) as Singleton<T>?;
    if (_singleton?.onRemove != null) {
      _singleton!.onRemove!(
        _singleton.dependency,
      );
    }
    return _singleton?.dependency;
  }

  /// removes an instance from the lazy hasmap
  void lazyRemove<T>({String? tag}) {
    final key = _getKey(T, tag);
    _lazyVars.remove(key);
  }

  /// delete all dependencies
  void clear() {
    _factoryVars.clear();
    _asyncVars.clear();
    _vars.clear();
    _lazyVars.clear();
  }
}
