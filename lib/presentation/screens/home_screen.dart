import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/main_viewmodel.dart';
import '../widgets/dashboard_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MainViewModel>();

    // Определяем цвета и иконку статуса
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.link_off;

    if (vm.status == "Transmitting...") {
      statusColor = Colors.greenAccent;
      statusIcon = Icons.wifi_tethering;
    } else if (vm.status.startsWith("Error")) {
      statusColor = Colors.redAccent;
      statusIcon = Icons.error_outline;
    } else if (vm.status.startsWith("Bound")) {
      statusColor = Colors.blueAccent;
      statusIcon = Icons.link;
    } else if (vm.status.startsWith("Binding")) {
      statusColor = Colors.orangeAccent;
      statusIcon = Icons.leak_add;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Row(
          children: [
            Icon(statusIcon, color: statusColor),
            const SizedBox(width: 10),
            const Text(
              "RC GROUND STATION",
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: vm.isJoy
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: vm.isJoy ? Colors.green : Colors.red),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.gamepad,
                  size: 16,
                  color: vm.isJoy ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 6),
                Text(
                  vm.isJoy ? "JOYSTICK OK" : "NO JOYSTICK",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // === ВЕРХНЯЯ ПАНЕЛЬ: ПОДКЛЮЧЕНИЕ ===
              _StatusCard(
                child: Column(
                  children: [
                    // Ряд 1: Выбор порта и Старт
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _StyledDropdown(
                            value: vm.ports.contains(vm.selectedPort)
                                ? vm.selectedPort
                                : null,
                            hint: "Select Serial Port",
                            items: vm.ports,
                            onChanged: (v) => vm.selectedPort = v,
                            icon: Icons.usb,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: ElevatedButton.icon(
                            icon: Icon(vm.isTx ? Icons.stop : Icons.play_arrow),
                            label: Text(vm.isTx ? "STOP" : "CONNECT"),
                            onPressed: vm.toggleTx,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: vm.isTx
                                  ? Colors.red.withValues(alpha: 0.8)
                                  : Colors.green.withValues(alpha: 0.8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Ряд 2: Настройка Дрона
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _StyledTextField(
                              label: "Drone MAC Address",
                              value: vm.droneMac,
                              onChanged: vm.updateMac,
                              icon: Icons.qr_code,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 80,
                            child: _StyledTextField(
                              label: "CH",
                              value: vm.wifiChannel.toString(),
                              onChanged: vm.updateChannel,
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: vm.isTx ? vm.startBind : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: vm.isBinding
                                  ? Colors.orange
                                  : Colors.blueGrey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(vm.isBinding ? "..." : "BIND"),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      "STATUS: ${vm.status.toUpperCase()}",
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // === ПАНЕЛЬ ПРЕСЕТОВ ===
              _StatusCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.settings_applications,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<dynamic>(
                          value: vm.presets.contains(vm.currentPreset)
                              ? vm.currentPreset
                              : null,
                          dropdownColor: const Color(0xFF2C2C2C),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          hint: const Text(
                            "Select Profile",
                            style: TextStyle(color: Colors.grey),
                          ),
                          items: vm.presets
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) vm.applyPreset(v);
                          },
                        ),
                      ),
                    ),

                    // Переименовать
                    _IconButtonAction(
                      icon: Icons.edit,
                      color: Colors.amber,
                      tooltip: "Rename Preset",
                      onPressed: () => _showRenameDialog(context, vm),
                    ),

                    // Сохранить
                    _IconButtonAction(
                      icon: Icons.save,
                      color: Colors.blue,
                      tooltip: "Save Changes",
                      onPressed: () {
                        vm.saveCurrentPreset();
                        _snack(context, "Saved '${vm.currentPreset?.name}'");
                      },
                    ),

                    // Новый
                    _IconButtonAction(
                      icon: Icons.add_circle_outline,
                      color: Colors.green,
                      tooltip: "New Preset",
                      onPressed: () => _showSaveAsDialog(context, vm),
                    ),

                    // Удалить
                    _IconButtonAction(
                      icon: Icons.delete_outline,
                      color: Colors.red,
                      tooltip: "Delete Preset",
                      onPressed: vm.presets.length > 1
                          ? () => _showDeleteDialog(context, vm)
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // === ГЛАВНАЯ ПАНЕЛЬ (ОСИ И ТУМБЛЕРЫ) ===
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Левая колонка: ОСИ
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _axis(
                          vm,
                          "ROLL",
                          "r",
                          vm.raw.roll,
                          vm.state.roll,
                          Colors.cyanAccent,
                          vm.invR,
                          vm.exR,
                          vm.dzR,
                        ),
                        _axis(
                          vm,
                          "PITCH",
                          "p",
                          vm.raw.pitch,
                          vm.state.pitch,
                          Colors.greenAccent,
                          vm.invP,
                          vm.exP,
                          vm.dzP,
                        ),
                        _axis(
                          vm,
                          "YAW",
                          "y",
                          vm.raw.yaw,
                          vm.state.yaw,
                          Colors.orangeAccent,
                          vm.invY,
                          vm.exY,
                          vm.dzY,
                        ),
                        _axis(
                          vm,
                          "THROTTLE",
                          "t",
                          vm.raw.throttle,
                          vm.state.throttle,
                          Colors.redAccent,
                          vm.invT,
                          vm.exT,
                          vm.dzT,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Правая колонка: СВИТЧИ
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize
                            .min, // ВАЖНО: Занимаем минимум места по вертикали
                        children: [
                          const Text(
                            "SWITCHES",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 8),
                          SwitchDisplay(
                            label: vm.nmA1,
                            active: vm.state.isArm,
                            onLabelChanged: (v) => vm.updateLabel('a1', v),
                          ),
                          SwitchDisplay(
                            label: vm.nmA2,
                            active: vm.state.isMode,
                            onLabelChanged: (v) => vm.updateLabel('a2', v),
                          ),
                          SwitchDisplay(
                            label: vm.nmA3,
                            active: vm.state.isExtra,
                            onLabelChanged: (v) => vm.updateLabel('a3', v),
                          ),
                          const SizedBox(height: 24),
                          const Icon(
                            Icons.wifi,
                            color: Colors.white10,
                            size: 48,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // Хелпер для создания AxisDisplay
  Widget _axis(
    MainViewModel vm,
    String defaultLabel,
    String k,
    double r,
    double p,
    Color c,
    bool i,
    double e,
    double d,
  ) {
    double s = 1.0;
    String currentLabel = defaultLabel; // Получаем имя из VM

    if (k == 'r') {
      s = vm.scR;
      currentLabel = vm.nmR;
    }
    if (k == 'p') {
      s = vm.scP;
      currentLabel = vm.nmP;
    }
    if (k == 'y') {
      s = vm.scY;
      currentLabel = vm.nmY;
    }
    if (k == 't') {
      s = vm.scT;
      currentLabel = vm.nmT;
    }

    return AxisDisplay(
      label: currentLabel, // Передаем динамическое имя
      onLabelChanged: (val) => vm.updateLabel(k, val), // Callback
      raw: r * (i ? -1 : 1),
      proc: p,
      ex: e,
      dz: d,
      sc: s,
      inv: i,
      color: c,
      onInv: (v) => vm.updateInv(k, v ?? false),
      onEx: (v) => vm.updateEx(k, v),
      onDz: (v) => vm.updateDz(k, v),
      onSc: (v) => vm.updateSc(k, v),
    );
  }

  // --- ДИАЛОГИ ---

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF333333),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSaveAsDialog(BuildContext context, MainViewModel vm) {
    final c = TextEditingController(text: "${vm.currentPreset?.name}_copy");
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: const Text("New Preset", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: c,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Name",
            labelStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (c.text.isNotEmpty) {
                vm.saveNewPreset(c.text);
                Navigator.pop(d);
                _snack(context, "Created '${c.text}'");
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, MainViewModel vm) {
    final c = TextEditingController(text: vm.currentPreset?.name);
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: const Text(
          "Rename Preset",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: c,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "New Name",
            labelStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.amber),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              if (c.text.isNotEmpty && c.text != vm.currentPreset?.name) {
                vm.renameCurrentPreset(c.text);
                Navigator.pop(d);
                _snack(context, "Renamed to '${c.text}'");
              } else {
                Navigator.pop(d);
              }
            },
            child: const Text("Rename", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, MainViewModel vm) {
    showDialog(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        title: const Text(
          "Delete Preset?",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Delete '${vm.currentPreset?.name}'?",
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              vm.deleteCurrentPreset();
              Navigator.pop(d);
              _snack(context, "Deleted");
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}

// --- ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ ---

class _StatusCard extends StatelessWidget {
  final Widget child;
  const _StatusCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StyledDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData icon;

  const _StyledDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : null,
          isExpanded: true,
          icon: Icon(icon, color: Colors.grey, size: 20),
          dropdownColor: const Color(0xFF2C2C2C),
          hint: Text(
            hint,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          style: const TextStyle(color: Colors.white),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final IconData? icon;
  final bool isNumber;

  const _StyledTextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon,
    this.isNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value)
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: value.length),
        ),
      onChanged: onChanged,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
        prefixIcon: icon != null
            ? Icon(icon, size: 16, color: Colors.grey)
            : null,
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }
}

class _IconButtonAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final String tooltip;

  const _IconButtonAction({
    required this.icon,
    required this.color,
    this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: onPressed != null ? color : Colors.grey),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}
