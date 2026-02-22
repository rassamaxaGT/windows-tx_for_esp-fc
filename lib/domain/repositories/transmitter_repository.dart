import '../entities/rc_state.dart';

abstract class TransmitterRepository {
  List<String> getAvailablePorts();
  Future<void> connect(String portName, int baudRate);
  Future<void> disconnect();
  void sendState(RCState state);
  bool get isConnected;
}