import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/rc_state.dart';
import '../../domain/entities/preset.dart';
import '../../domain/repositories/joystick_repository.dart';
import '../../data/repositories/serial_transmitter_repository.dart';

class MainViewModel extends ChangeNotifier {
  final JoystickRepository _joyRepo;
  final SerialTransmitterRepository _txRepo;
  Timer? _timer;

  RCState state = const RCState();
  RCState raw = const RCState();

  List<RCPreset> presets = [];
  RCPreset? currentPreset;

  String? _selectedPort;
  String? get selectedPort => _selectedPort;
  set selectedPort(String? v) {
    _selectedPort = v;
    notifyListeners();
  }

  // Параметры связи
  String droneMac = "80:F3:DA:5D:C2:61";
  int wifiChannel = 1;
  bool isBinding = false;
  String status = "Ready";

  // Настройки осей (inv, ex, dz, sc...)
  bool invR = false, invP = true, invY = false, invT = false;
  double exR = 1.0, exP = 1.0, exY = 1.0, exT = 1.0;
  double dzR = 0.04, dzP = 0.04, dzY = 0.04, dzT = 0.0;
  double scR = 1.0, scP = 1.0, scY = 1.0, scT = 1.0;

  // Переменные для имен осей (State)
  String nmR = "ROLL", nmP = "PITCH", nmY = "YAW", nmT = "THROTTLE";
  String nmA1 = "ARM", nmA2 = "MODE", nmA3 = "FS";

  MainViewModel(this._joyRepo, this._txRepo) {
    _init();
    _txRepo.incomingData.listen(_onDataFromDrone);
  }

  void _onDataFromDrone(Uint8List data) {
    if (data.isEmpty) return;
    if (data[0] == 0xFE) {
      _txRepo.sendPairResponse(wifiChannel);
      if (isBinding) {
        isBinding = false;
        status = "Bound!";
        notifyListeners();
      }
    }
  }

  void _init() async {
    await _joyRepo.initialize();
    await _loadSettings(); // Загружаем и настройки моста, и пресеты
    _timer = Timer.periodic(const Duration(milliseconds: 20), (_) => _tick());
  }

  void _tick() {
    raw = _joyRepo.poll();
    state = raw.copyWith(
      roll: _process(raw.roll, invR, dzR, exR, scR),
      pitch: _process(raw.pitch, invP, dzP, exP, scP),
      yaw: _process(raw.yaw, invY, dzY, exY, scY),
      throttle: _process(raw.throttle, invT, dzT, exT, scT),
    );

    if (_txRepo.isConnected) {
      try {
        _txRepo.sendState(state);
        if (!isBinding && !status.startsWith("Error")) {
          status = "Transmitting...";
        }
      } catch (e) {
        status = "Error: Connection Lost";
      }
    }
    notifyListeners();
  }

  double _process(double v, bool inv, double dz, double ex, double sc) {
    double val = v * (inv ? -1 : 1);
    double absV = val.abs();
    if (absV < dz) return 0.0;
    double res = pow((absV - dz) / (1.0 - dz), ex).toDouble();
    return val.sign * res * sc;
  }

  void toggleTx() async {
    if (_txRepo.isConnected) {
      await _txRepo.disconnect();
    } else if (selectedPort != null) {
      try {
        await _txRepo.connect(selectedPort!, 115200);
        await Future.delayed(const Duration(milliseconds: 100));
        await _txRepo.configureBridge(droneMac, wifiChannel);
        status = "Transmitting...";
      } catch (e) {
        status = "Error: $e";
      }
    }
    notifyListeners();
  }

  void startBind() {
    if (!_txRepo.isConnected) return;
    isBinding = true;
    status = "Binding (Wait for drone)...";
    notifyListeners();
  }

  // --- ЗАГРУЗКА И СОХРАНЕНИЕ ---

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Загрузка настроек моста
    droneMac = prefs.getString('droneMac') ?? "80:F3:DA:5D:C2:61";
    wifiChannel = prefs.getInt('wifiChannel') ?? 1;

    // 2. Загрузка пресетов
    final String? presetsData = prefs.getString('presets');
    if (presetsData != null) {
      try {
        final List decoded = jsonDecode(presetsData);
        presets = decoded.map((e) => RCPreset.fromJson(e)).toList();
      } catch (e) {
        stdout.writeln("Error loading presets: $e");
        presets = [];
      }
    }

    // 3. Если пусто, создаем дефолтный
    if (presets.isEmpty) {
      presets = [const RCPreset(name: "Default")];
    }

    // 4. Применяем первый пресет, чтобы настройки загрузились в UI
    applyPreset(presets.first);
  }

  void updateMac(String v) {
    droneMac = v;
    _saveBridgeSettings();
  }

  void updateChannel(String v) {
    wifiChannel = int.tryParse(v) ?? 1;
    _saveBridgeSettings();
  }

  void _saveBridgeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('droneMac', droneMac);
    await prefs.setInt('wifiChannel', wifiChannel);
  }

  Future<void> _stopTxSafe({String? errorMsg}) async {
    try {
      await _txRepo.disconnect();
    } catch (_) {}
    status = errorMsg != null ? "Error: $errorMsg" : "Ready";
  }

  // --- PRESETS LOGIC ---

  Future<void> _savePresetsToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'presets',
      jsonEncode(presets.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
  }

  // Сохранить текущие настройки в ТЕКУЩИЙ пресет (перезапись)
  void saveCurrentPreset() {
    if (currentPreset == null) return;
    saveNewPreset(currentPreset!.name);
  }

  // Сохранить текущие настройки как НОВЫЙ пресет (или перезаписать по имени)
  void saveNewPreset(String name) {
    final newPreset = RCPreset(
      name: name,
      // ... все числовые параметры ...
      invRoll: invR,
      invPitch: invP,
      invYaw: invY,
      invThrottle: invT,
      exRoll: exR,
      exPitch: exP,
      exYaw: exY,
      exThr: exT,
      dzRoll: dzR,
      dzPitch: dzP,
      dzYaw: dzY,
      dzThr: dzT,
      scRoll: scR,
      scPitch: scP,
      scYaw: scY,
      scThr: scT,
      // Сохраняем текущие имена
      nRoll: nmR,
      nPitch: nmP,
      nYaw: nmY,
      nThr: nmT,
      nAux1: nmA1,
      nAux2: nmA2,
      nAux3: nmA3,
    );
    // ... логика сохранения ...
    final index = presets.indexWhere((e) => e.name == name);
    if (index != -1) {
      presets[index] = newPreset;
    } else {
      presets.add(newPreset);
    }
    currentPreset = newPreset;
    _savePresetsToDisk();
  }

  void applyPreset(RCPreset p) {
    currentPreset = p;
    // Применяем числовые настройки...
    invR = p.invRoll;
    invP = p.invPitch;
    invY = p.invYaw;
    invT = p.invThrottle;
    exR = p.exRoll;
    exP = p.exPitch;
    exY = p.exYaw;
    exT = p.exThr;
    dzR = p.dzRoll;
    dzP = p.dzPitch;
    dzY = p.dzYaw;
    dzT = p.dzThr;
    scR = p.scRoll;
    scP = p.scPitch;
    scY = p.scYaw;
    scT = p.scThr;

    // Применяем имена
    nmR = p.nRoll;
    nmP = p.nPitch;
    nmY = p.nYaw;
    nmT = p.nThr;
    nmA1 = p.nAux1;
    nmA2 = p.nAux2;
    nmA3 = p.nAux3;

    notifyListeners();
  }

  // Удалить текущий пресет
  void deleteCurrentPreset() {
    if (currentPreset == null) return;

    if (presets.length <= 1) {
      saveNewPreset("Default");
      return;
    }

    presets.removeWhere((e) => e.name == currentPreset!.name);

    if (presets.isNotEmpty) {
      applyPreset(presets.first);
    }

    _savePresetsToDisk();
  }

  void updateLabel(String key, String value) {
    if (value.trim().isEmpty) return;
    String v = value.trim().toUpperCase(); // Принудительно CapsLock для стиля

    if (key == 'r') nmR = v;
    if (key == 'p') nmP = v;
    if (key == 'y') nmY = v;
    if (key == 't') nmT = v;
    if (key == 'a1') nmA1 = v;
    if (key == 'a2') nmA2 = v;
    if (key == 'a3') nmA3 = v;

    notifyListeners();
  }

  // --- UI UPDATERS ---

  void updateInv(String axis, bool v) {
    if (axis == 'r') invR = v;
    if (axis == 'p') invP = v;
    if (axis == 'y') invY = v;
    if (axis == 't') invT = v;
  }

  void updateEx(String axis, double v) {
    if (axis == 'r') exR = v;
    if (axis == 'p') exP = v;
    if (axis == 'y') exY = v;
    if (axis == 't') exT = v;
  }

  void updateDz(String axis, double v) {
    if (axis == 'r') dzR = v;
    if (axis == 'p') dzP = v;
    if (axis == 'y') dzY = v;
    if (axis == 't') dzT = v;
  }

  void updateSc(String axis, double v) {
    if (axis == 'r') scR = v;
    if (axis == 'p') scP = v;
    if (axis == 'y') scY = v;
    if (axis == 't') scT = v;
  }

  void renameCurrentPreset(String newName) {
    if (currentPreset == null || newName.trim().isEmpty) return;

    final name = newName.trim();

    // Проверяем, не занято ли имя (кроме текущего)
    if (presets.any((p) => p.name == name && p != currentPreset)) {
      // Имя занято - можно выбросить ошибку или просто выйти
      return;
    }

    // Создаем пресет с НОВЫМ именем, но ТЕКУЩИМИ настройками
    final updatedPreset = RCPreset(
      name: name,
      invRoll: invR,
      invPitch: invP,
      invYaw: invY,
      invThrottle: invT,
      exRoll: exR,
      exPitch: exP,
      exYaw: exY,
      exThr: exT,
      dzRoll: dzR,
      dzPitch: dzP,
      dzYaw: dzY,
      dzThr: dzT,
      scRoll: scR,
      scPitch: scP,
      scYaw: scY,
      scThr: scT,
    );

    // Находим индекс старого пресета и заменяем его
    final index = presets.indexOf(currentPreset!);
    if (index != -1) {
      presets[index] = updatedPreset;
      currentPreset = updatedPreset;
      _savePresetsToDisk();
    }
  }

  // --- UI GETTERS ---

  bool get isJoy => _joyRepo.isConnected;
  bool get isTx => _txRepo.isConnected;
  List<String> get ports => _txRepo.getAvailablePorts();

  @override
  void dispose() {
    _timer?.cancel();
    _joyRepo.dispose();
    _stopTxSafe();
    super.dispose();
  }
}
