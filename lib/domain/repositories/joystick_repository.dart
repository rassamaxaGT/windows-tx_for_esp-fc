import '../entities/rc_state.dart';

abstract class JoystickRepository {
  Future<void> initialize();
  RCState poll();
  bool get isConnected;
  void dispose(); // Добавлено для очистки нативной памяти
}