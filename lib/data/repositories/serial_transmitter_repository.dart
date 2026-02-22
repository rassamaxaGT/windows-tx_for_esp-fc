import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import '../../domain/entities/rc_state.dart';
import '../../domain/repositories/transmitter_repository.dart';
import '../protocols/aetr_protocol_encoder.dart';
import '../protocols/esp_now_bridge_protocol.dart';

class SerialTransmitterRepository implements TransmitterRepository {
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription? _subscription; // Добавляем хранение подписки
  
  final _incomingController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get incomingData => _incomingController.stream;

  @override
  List<String> getAvailablePorts() => SerialPort.availablePorts;

  @override
  bool get isConnected => _port != null && _port!.isOpen;

  @override
  Future<void> connect(String portName, int baudRate) async {
    if (_port != null) await disconnect();

    try {
      final port = SerialPort(portName);
      if (!port.openReadWrite()) {
        port.dispose();
        throw Exception("Could not open port");
      }

      final config = SerialPortConfig()
        ..baudRate = baudRate
        ..bits = 8
        ..stopBits = 1
        ..parity = SerialPortParity.none;
      port.config = config;
      config.dispose();

      _port = port;

      // Запускаем чтение
      _reader = SerialPortReader(_port!, timeout: 10);
      // Сохраняем подписку, чтобы корректно её отменить
      _subscription = _reader!.stream.listen(
        _handleIncomingData,
        onError: (error) {
          stdout.writeln("Serial Read Error: $error");
        },
        onDone: () {
          stdout.writeln("Serial Read Done");
        }
      );

      stdout.writeln("✅ Serial Bridge Connected");
    } catch (e) {
      _cleanup(true); // Аварийная очистка
      rethrow;
    }
  }

  final List<int> _readBuf = [];
  void _handleIncomingData(Uint8List data) {
    _readBuf.addAll(data);
    while (_readBuf.isNotEmpty) {
      if (_readBuf[0] != BridgeCommands.recv) {
        _readBuf.removeAt(0);
        continue;
      }
      if (_readBuf.length < 2) break;
      int len = _readBuf[1];
      if (_readBuf.length < 2 + len) break;
      
      final payload = Uint8List.fromList(_readBuf.sublist(2, 2 + len));
      _readBuf.removeRange(0, 2 + len);
      _incomingController.add(payload);
    }
  }

  Future<void> configureBridge(String macStr, int channel) async {
    if (_port == null) return;
    final mac = parseMacAddress(macStr);
    final packet = BytesBuilder();
    packet.addByte(BridgeCommands.config);
    packet.addByte(channel);
    packet.add(mac);
    try {
      _port!.write(packet.toBytes());
    } catch (e) {
      stdout.writeln("Config write error: $e");
    }
  }

  @override
  void sendState(RCState state) {
    if (_port == null) return;
    try {
      final rcPacket = AetrProtocolEncoder.encode(state);
      _sendRaw(rcPacket);
    } catch (e) {
      // При ошибке записи (обрыв шнура) - аварийное отключение
      _cleanup(true); 
      throw Exception("Device Lost");
    }
  }

  void sendPairResponse(int channel) {
    final resp = PairResponseEncoder.encode(channel);
    _sendRaw(resp);
  }

  void _sendRaw(Uint8List data) {
    final p = _port;
    if (p == null || !p.isOpen) return;
    
    final packet = BytesBuilder();
    packet.addByte(BridgeCommands.send);
    packet.addByte(data.length);
    packet.add(data);
    
    p.write(packet.toBytes());
  }

  @override
  Future<void> disconnect() async => _cleanup(false);

  /// [emergency] = true, если выдернули шнур (ошибка записи).
  /// [emergency] = false, если нажали кнопку STOP.
  Future<void> _cleanup(bool emergency) async {
    // 1. Снимаем ссылку, чтобы остановить отправку данных
    final p = _port;
    _port = null;

    // 2. Останавливаем чтение ПЕРЕД закрытием порта
    if (_subscription != null) {
      await _subscription!.cancel();
      _subscription = null;
    }
    
    if (_reader != null) {
      _reader!.close();
      _reader = null;
    }

    if (p != null) {
      if (!emergency) {
        // Если штатное отключение - даем время ридеру остановиться
        await Future.delayed(const Duration(milliseconds: 100));
        try {
          if (p.isOpen) p.close();
        } catch (e) {
          stdout.writeln("Port close error: $e");
        }
      }
      
      // ВАЖНО: Мы НЕ вызываем p.dispose() ни в каком случае.
      // 1. При emergency (обрыв): память уже битая, dispose вызовет краш.
      // 2. При штатном: Reader может все еще держать ссылки внутри C-библиотеки,
      //    и ручной dispose вызовет Heap Corruption.
      // Dart Garbage Collector сам очистит этот объект позже, когда это будет безопасно.
    }
  }

  void dispose() => _incomingController.close();
}