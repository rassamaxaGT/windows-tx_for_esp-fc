import 'dart:typed_data';
import '../../domain/entities/rc_state.dart';

class AetrProtocolEncoder {
  static Uint8List encode(RCState state) {
    // Размер MessageRc: Type(1) + 4*Chan(8) + 4*Aux(4) + Checksum(1) = 14 байт
    final buffer = ByteData(13); // Сначала готовим тело (13 байт)

    // [0] Type = 1 (RC_DATA)
    buffer.setUint8(0, 0x01);

    int toPwm(double v) => (1500 + (v * 500)).round().clamp(1000, 2000);
    int toAux(bool active) {
      int pwm = active ? 2000 : 1000;
      return (pwm - 1500) ~/ 5; // -100 или 100
    }

    // [1..8] Channels (Little Endian - стандарт для ESP32/Arduino)
    buffer.setInt16(1, toPwm(state.roll), Endian.little);
    buffer.setInt16(3, toPwm(state.pitch), Endian.little);
    buffer.setInt16(5, toPwm(state.throttle), Endian.little);
    buffer.setInt16(7, toPwm(state.yaw), Endian.little);

    // [9..12] Aux (ch5, ch6, ch7, ch8)
    buffer.setInt8(9, toAux(state.isArm));
    buffer.setInt8(10, toAux(state.isMode));
    buffer.setInt8(11, toAux(state.isExtra));
    buffer.setInt8(12, 0); // Aux 4

    // Считаем Checksum (XOR всего тела с начальным 0x55)
    final body = buffer.buffer.asUint8List();
    int csum = 0x55; 
    for (var b in body) {
      csum ^= b;
    }

    // СОБИРАЕМ ПАКЕТ: Только Body + Checksum (итого 14 байт)
    // Больше никаких 0xFE 0xFE!
    final packet = BytesBuilder();
    packet.add(body);
    packet.addByte(csum);

    return packet.toBytes();
  }
}