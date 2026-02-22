import 'dart:typed_data';

class BridgeCommands {
  static const int config = 0xC0; // Установка MAC и канала
  static const int send = 0xD0;   // Отправка данных в эфир
  static const int recv = 0x52;   // Получение данных (символ 'R')
}

class PairResponseEncoder {
  static Uint8List encode(int channel) {
    // Структура: Type(0xFF) + Channel(1) + Checksum(1)
    final buffer = ByteData(3);
    buffer.setUint8(0, 0xFF); 
    buffer.setUint8(1, channel);
    
    // Checksum: 0x55 ^ type ^ channel
    int csum = 0x55 ^ 0xFF ^ channel;
    buffer.setUint8(2, csum);
    
    return buffer.buffer.asUint8List();
  }
}

Uint8List parseMacAddress(String macStr) {
  try {
    final clean = macStr.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    if (clean.length != 12) throw Exception();
    final bytes = Uint8List(6);
    for (int i = 0; i < 6; i++) {
      bytes[i] = int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  } catch (e) {
    // В случае ошибки возвращаем широковещательный адрес
    return Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]);
  }
}