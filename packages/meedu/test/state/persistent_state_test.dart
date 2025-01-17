import 'package:equatable/equatable.dart';
import 'package:meedu/meedu.dart';
import 'package:test/test.dart';

void main() {
  test(
    'PersistentStateMixin',
    () {
      final storage = MyStorage();
      const key1 = 'key1';
      const key2 = 'key2';
      final controller1 = ShoppingCartController(
        storage: storage,
        storageKey: key1,
      );
      final controller2 = ShoppingCartController(
        storage: storage,
        storageKey: key2,
      );
      expect(controller1.state.products.length, 0);
      controller1.addProduct(
        Product(name: 'p1', price: 0),
      );
      expect(controller1.state.products.length, 1);
      expect(controller2.state.products.length, 0);

      final controllerCopy1 = ShoppingCartController(
        storage: storage,
        storageKey: key1,
      );
      expect(controllerCopy1.state.products.length, 1);
      storage.delete(key1);

      final controllerCopy11 = ShoppingCartController(
        storage: storage,
        storageKey: key1,
      );

      expect(controllerCopy11.state.products.length, 0);

      final controllerFail1 = ShoppingCartControllerForceFail(
        storage: storage,
        storageKey: key1,
      );
      controllerFail1.addProduct(
        Product(name: 'p2', price: 0),
      );
      final controllerCopyFail1 = ShoppingCartControllerForceFail(
        storage: storage,
        storageKey: key1,
      );
      expect(controllerCopyFail1.state.products.length, 0);
    },
  );

  test(
    'PersistentStateMixin > cities',
    () async {
      final storage = MyStorage();
      final controller = CityPickerController(storage);
      expect(controller.state.loading, true);
      await controller.loadCities();
      expect(controller.state.loading, false);
      expect(controller.state.cities.isNotEmpty, true);

      /// create a new controller and check the cached state
      expect(
        CityPickerController(storage).state.cities.isNotEmpty,
        true,
      );
    },
  );
}

class ShoppingCartController extends StateNotifier<ShoppingCartState> with PersistentStateMixin {
  ShoppingCartController({
    required this.storageKey,
    required this.storage,
  }) : super(
          ShoppingCartState(
            loading: false,
            products: [],
          ),
        );

  @override
  final PersistentStateStorage storage;

  @override
  final String storageKey;

  void addProduct(Product product) {
    state = ShoppingCartState(
      loading: state.loading,
      products: [
        ...state.products,
        product,
      ],
    );
  }

  void removeProduct() {
    final copy = [...state.products];
    copy.removeLast();
    state = ShoppingCartState(
      loading: state.loading,
      products: copy,
    );
  }

  @override
  ShoppingCartState fromJson(Map<String, dynamic> json) {
    return ShoppingCartState.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(ShoppingCartState state) {
    return state.toJson();
  }

  @override
  void onStateChanged(ShoppingCartState oldState, ShoppingCartState currentState) {
    super.onStateChanged(oldState, currentState);
  }
}

class ShoppingCartControllerForceFail extends StateNotifier<ShoppingCartState>
    with PersistentStateMixin<ShoppingCartState> {
  ShoppingCartControllerForceFail({
    required this.storageKey,
    required this.storage,
  }) : super(
          ShoppingCartState(
            loading: false,
            products: [],
          ),
        );

  @override
  final PersistentStateStorage storage;

  @override
  final String storageKey;

  void addProduct(Product product) {
    state = ShoppingCartState(
      loading: state.loading,
      products: [
        ...state.products,
        product,
      ],
    );
  }

  @override
  ShoppingCartState fromJson(Map<String, dynamic> json) {
    throw Exception('');
  }

  @override
  Map<String, dynamic> toJson(ShoppingCartState state) {
    return state.toJson();
  }
}

class ShoppingCartState {
  final bool loading;
  final List<Product> products;

  ShoppingCartState({
    required this.loading,
    required this.products,
  });

  Map<String, dynamic> toJson() {
    return {
      'loading': loading,
      'products': [
        ...products.map(
          (e) => e.toJson(),
        ),
      ],
    };
  }

  factory ShoppingCartState.fromJson(Map<String, dynamic> json) {
    return ShoppingCartState(
      loading: json['loading'],
      products: [
        ...(json['products'] as List).map(
          (e) => Product.fromJson(e),
        ),
      ],
    );
  }
}

class Product {
  final String name;
  final double price;

  Product({
    required this.name,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'],
      price: json['price'],
    );
  }
}

class MyStorage implements PersistentStateStorage {
  final Map<String, Map<String, dynamic>> _states = {};

  @override
  Future<void> delete(String key) async {
    _states.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _states.clear();
  }

  @override
  Map<String, dynamic>? get(String key) {
    return _states[key];
  }

  @override
  Future<void> save(String key, Map<String, dynamic> json) async {
    _states[key] = json;
  }
}

class CityPickerController extends StateNotifier<CityPickerState> with PersistentStateMixin {
  CityPickerController(
    this.storage,
  ) : super(CityPickerState.initialState);

  @override
  final PersistentStateStorage storage;

  Future<void> loadCities() async {
    /// if you don't have a cached state
    if (state.cities.isEmpty) {
      final cities = await getCitiesFromYourAPI();
      state = state.copyWith(
        loading: false,
        cities: cities,
      );
    }
  }

  @override
  CityPickerState? fromJson(Map<String, dynamic> json) {
    return CityPickerState.fromJson(json);
  }

  @override
  String get storageKey => 'my_unique_id';

  @override
  Map<String, dynamic>? toJson(CityPickerState state) {
    if (state.cities.isNotEmpty) {
      return state.toJson();
    }
    return null;
  }
}

class CityPickerState extends Equatable {
  final bool loading;
  final List<City> cities;

  const CityPickerState({
    required this.loading,
    required this.cities,
  });

  static CityPickerState get initialState => CityPickerState(
        loading: true,
        cities: [],
      );

  CityPickerState copyWith({
    bool? loading,
    List<City>? cities,
  }) {
    return CityPickerState(
      loading: loading ?? this.loading,
      cities: cities ?? this.cities,
    );
  }

  factory CityPickerState.fromJson(Map<String, dynamic> json) {
    return CityPickerState(
      loading: json['loading'],
      cities: (json['cities'] as List)
          .map(
            (e) => City.fromJson(e),
          )
          .toList(),
    );
  }

  /// conver this instance to one JSON map
  Map<String, dynamic> toJson() => {
        'loading': loading,
        'cities': cities
            .map(
              (e) => e.toJson(),
            )
            .toList(),
      };

  @override
  List<Object?> get props => [
        loading,
        cities,
      ];
}

class City extends Equatable {
  final int id;
  final String name;

  const City({
    required this.id,
    required this.name,
  });

  /// convert this instance to one JSON map
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  /// return one instance of City from a JSON map
  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'],
      name: json['name'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
      ];
}

Future<List<City>> getCitiesFromYourAPI() async {
  await Future.delayed(
    Duration(milliseconds: 100),
  );
  return const [
    City(id: 1, name: 'Quito'),
  ];
}
