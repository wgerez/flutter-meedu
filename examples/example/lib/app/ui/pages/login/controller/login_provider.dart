import 'package:example/app/inject_dependencies.dart';
import 'package:flutter_meedu/meedu.dart';
import 'login_controller.dart';
import 'login_state.dart';

final loginProvider = StateProvider<LoginController, LoginState>(
  (_) => LoginController(
    loginUseCase: UsesCases.login,
  ),
);
