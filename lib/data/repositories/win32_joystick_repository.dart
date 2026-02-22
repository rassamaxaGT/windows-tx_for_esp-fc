import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import '../../domain/entities/rc_state.dart';
import '../../domain/repositories/joystick_repository.dart';

final class JOYINFOEX extends Struct {
  @Uint32() external int dwSize;
  @Uint32() external int dwFlags;
  @Uint32() external int dwXpos;
  @Uint32() external int dwYpos;
  @Uint32() external int dwZpos;
  @Uint32() external int dwRpos;
  @Uint32() external int dwUpos;
  @Uint32() external int dwVpos;
  @Uint32() external int dwButtons;
  @Uint32() external int dwButtonNumber;
  @Uint32() external int dwPOV;
  @Uint32() external int dwReserved1;
  @Uint32() external int dwReserved2;
}

typedef JoyGetPosExNative = Uint32 Function(Uint32 uJoyID, Pointer<JOYINFOEX> pji);
typedef JoyGetPosExDart = int Function(int uJoyID, Pointer<JOYINFOEX> pji);

class Win32JoystickRepository implements JoystickRepository {
  late DynamicLibrary _lib;
  late JoyGetPosExDart _joyGetPosEx;
  
  // Выделяем память один раз, а не каждый кадр
  Pointer<JOYINFOEX>? _pJoy; 
  
  int _id = -1;
  int _prevBtn = 0;
  bool _arm = false, _mode = false, _fs = false;

  Win32JoystickRepository() {
    try {
      _lib = DynamicLibrary.open('winmm.dll');
      _joyGetPosEx = _lib
          .lookup<NativeFunction<JoyGetPosExNative>>('joyGetPosEx')
          .asFunction();
      
      // Инициализируем структуру в памяти
      _pJoy = calloc<JOYINFOEX>();
      _pJoy!.ref.dwSize = sizeOf<JOYINFOEX>();
      _pJoy!.ref.dwFlags = 0xFF; // JOY_RETURNALL
    } catch (e) {
      stdout.writeln("WinMM Init Error: $e");
    }
  }

  @override
  Future<void> initialize() async => _scan();

  void _scan() {
    if (_pJoy == null) return;
    
    for (int i = 0; i < 16; i++) {
      // 0 = JOYERR_NOERROR
      if (_joyGetPosEx(i, _pJoy!) == 0) {
        _id = i;
        stdout.writeln("Joystick found on ID: $_id");
        break;
      }
    }
  }

  @override
  bool get isConnected => _id != -1;

  @override
  RCState poll() {
    if (_pJoy == null) return const RCState();

    // Если джойстик не найден, пробуем найти (редко, можно добавить счетчик кадров)
    if (_id == -1) {
      // Простая логика рескана: можно вызывать не каждый кадр для оптимизации, 
      // но joyGetPosEx быстрый, если ID не валиден.
      _scan();
      return const RCState();
    }

    final result = _joyGetPosEx(_id, _pJoy!);

    // Если джойстик отключили (Result != 0)
    if (result != 0) {
      _id = -1; // Сбрасываем ID, чтобы запустить поиск заново
      return const RCState(); // Возвращаем нули
    }

    double norm(int v) => (v.clamp(0, 65535) - 32768) / 32768.0;
    
    // Чтение кнопок
    int b = _pJoy!.ref.dwButtons;
    
    // Toggle логика
    if ((b & 1) != 0 && (_prevBtn & 1) == 0) _arm = !_arm;
    if ((b & 2) != 0 && (_prevBtn & 2) == 0) _mode = !_mode;
    if ((b & 4) != 0 && (_prevBtn & 4) == 0) _fs = !_fs;
    _prevBtn = b;

    return RCState(
      roll: norm(_pJoy!.ref.dwXpos),
      pitch: norm(_pJoy!.ref.dwYpos),
      throttle: norm(_pJoy!.ref.dwZpos),
      yaw: norm(_pJoy!.ref.dwRpos),
      isArm: _arm,
      isMode: _mode,
      isExtra: _fs,
    );
  }

  @override
  void dispose() {
    if (_pJoy != null) {
      calloc.free(_pJoy!);
      _pJoy = null;
    }
  }
}